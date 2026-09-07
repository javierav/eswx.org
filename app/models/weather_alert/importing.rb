# Importación de mensajes CAP.
#
# Los mensajes se procesan ordenados por su instante de emisión, porque un Update
# solo tiene sentido después de aquello que actualiza y el tar.gz no viene ordenado.
module WeatherAlert::Importing
  extend ActiveSupport::Concern

  FEED_CACHE_KEY = "aemet:feed:updated_at".freeze

  class_methods do
    # Devuelve cuántos avisos nuevos se han guardado.
    def refresh_from_aemet(feed: Aemet::Feed.new)
      return 0 unless feed_changed?(feed)

      imported = import_all(feed.messages)
      remember(feed)
      imported
    end

    def import_all(messages)
      transaction do
        messages.reject(&:minor?).sort_by(&:sent).count { |message| import(message) }
      end
    end

    def import(message)
      return false if message.identifier.blank? || message.zone_code.blank?
      return false if exists?(identifier: message.identifier)

      zone = WeatherZone.find_by(code: message.zone_code) || register_zone(message)
      return false if zone.nil?

      alert = create!(message.attributes.merge(weather_zone: zone))
      alert.supersede_referenced!
      alert.inherit_supersession!
      true
    end

    private

      def feed_changed?(feed)
        updated_at = feed.updated_at
        return true if updated_at.nil?

        Rails.cache.read(FEED_CACHE_KEY) != updated_at.iso8601
      end

      def remember(feed)
        Rails.cache.write(FEED_CACHE_KEY, feed.updated_at&.iso8601)
      end

      # Hoy las 233 zonas del shapefile cubren todo lo que emite AEMET. Si algún día
      # publican una delimitación nueva, se da de alta con el polígono del propio
      # mensaje en vez de perder el aviso.
      def register_zone(message)
        territory = WeatherTerritory.find_by(code: message.zone_code.first(4))
        geometry = message.geometry
        if territory.nil? || geometry.nil?
          Rails.logger.warn("[aemet] zona desconocida #{message.zone_code}: mensaje descartado")
          return nil
        end

        Rails.logger.info("[aemet] zona desconocida #{message.zone_code}: se da de alta")
        WeatherZone.create!(
          code: message.zone_code,
          name: message.zone_name.presence || message.zone_code,
          coastal: message.zone_code.end_with?("C"),
          weather_territory: territory,
          geometry: geometry,
          svg_path: MapProjection.path(geometry, canary: territory.province.region.canary?),
          **MapProjection.bounds(geometry)
        )
      end
  end

  # Un Update sustituye a todos los mensajes que referencia.
  def supersede_referenced!
    return if referenced_identifier_list.empty?

    self.class
      .where(identifier: referenced_identifier_list, superseded_at: nil)
      .update_all(superseded_at: sent, updated_at: Time.current)
  end

  # El tar.gz puede traer un mensaje después del Update que ya lo sustituyó, así
  # que un aviso puede nacer sustituido.
  def inherit_supersession!
    return if superseded_at.present?

    successor = next_version
    update_column(:superseded_at, successor.sent) if successor
  end
end
