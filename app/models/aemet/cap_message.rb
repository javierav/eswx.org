require "nokogiri"

module Aemet
  # Un mensaje CAP v1.2 de AEMET, según el anexo 3 del Plan Meteoalerta.
  #
  # No toca la base de datos: solo lee el XML y expone sus campos. Se queda con el
  # bloque <info> en español, porque cada aviso trae uno por idioma.
  class CapMessage
    LANGUAGE = "es-ES"
    ZONE_GEOCODE = "AEMET-Meteoalerta zona"
    PHENOMENON_EVENT_CODE = "AEMET-Meteoalerta fenomeno"
    LEVEL_PARAMETER = "AEMET-Meteoalerta nivel"
    VALUE_PARAMETER = "AEMET-Meteoalerta parametro"
    PROBABILITY_PARAMETER = "AEMET-Meteoalerta probabilidad"

    # Los mensajes sin aviso marcan hasta dónde llega la predicción y cubren todas
    # las zonas de una comunidad. No son avisos y no se guardan.
    NO_WARNING_SEVERITY = "Minor"

    attr_reader :raw

    def initialize(raw)
      @raw = raw
      @document = Nokogiri::XML(raw).tap(&:remove_namespaces!)
    end

    def identifier = text("identifier")
    def msg_type = text("msgType")
    def status = text("status")
    def severity = info_text("severity")
    def event = info_text("event")
    def headline = info_text("headline")
    def description = info_text("description")
    def instruction = info_text("instruction")
    def zone_code = geocode(ZONE_GEOCODE)
    def zone_name = info&.at_xpath("area/areaDesc")&.text&.strip
    def level = parameter(LEVEL_PARAMETER)
    def probability = parameter(PROBABILITY_PARAMETER)

    def sent = time("sent")
    def effective = info_time("effective")
    def onset = info_time("onset")
    def expires = info_time("expires")

    def minor? = severity == NO_WARNING_SEVERITY

    # AEMET no implementa Cancel: para retirar un aviso emite un Update que expira
    # en el mismo instante en que se envía y referencia a los que retira.
    def withdrawal? = expires.present? && sent.present? && expires <= sent

    # <references> son varias entradas "sender,identifier,sent" separadas por espacios.
    def referenced_identifiers
      text("references").to_s.split.filter_map { |reference| reference.split(",")[1] }
    end

    # El eventCode viene como "FF;Nombre del fenómeno".
    def phenomenon_code = phenomenon.first
    def phenomenon_name = phenomenon.last

    # El parámetro viene como "PP;Nombre;valor unidad"; interesa el texto legible.
    def parameter_description
      value = parameter(VALUE_PARAMETER)
      return if value.blank?

      fields = value.split(";")
      fields.length > 2 ? "#{fields[1]}: #{fields[2..].join('; ')}" : value
    end

    def attributes
      {
        identifier:, msg_type:, status:, sent:, effective:, onset:, expires:,
        severity:, level:, event:, headline:, description:, instruction:,
        phenomenon_code:, phenomenon_name:, probability:,
        parameter: parameter_description,
        referenced_identifiers: referenced_identifiers.join(" "),
        raw_cap: raw
      }
    end

    # Polígonos del propio mensaje, en GeoJSON. Son de baja resolución: solo se usan
    # si AEMET avisa sobre una zona que no está en la delimitación oficial.
    def geometry
      rings = info.xpath("area/polygon").map do |polygon|
        polygon.text.split.map { |pair| pair.split(",").reverse.map(&:to_f) }
      end
      return if rings.empty?

      { "type" => "MultiPolygon", "coordinates" => rings.map { |ring| [ ring ] } }
    end

    private

      def info
        @info ||= @document.xpath("//alert/info").find { |node|
          node.at_xpath("language")&.text == LANGUAGE
        } || @document.at_xpath("//alert/info")
      end

      def text(name) = @document.at_xpath("//alert/#{name}")&.text&.strip
      def info_text(name) = info&.at_xpath(name)&.text&.strip
      def time(name) = parse_time(text(name))
      def info_time(name) = parse_time(info_text(name))

      def parse_time(value) = value.present? ? Time.zone.parse(value) : nil

      def geocode(name)
        info&.at_xpath("area/geocode[valueName='#{name}']/value")&.text&.strip
      end

      def parameter(name)
        info&.at_xpath("parameter[valueName='#{name}']/value")&.text&.strip
      end

      def phenomenon
        @phenomenon ||= begin
          value = info&.at_xpath("eventCode[valueName='#{PHENOMENON_EVENT_CODE}']/value")&.text.to_s
          code, name = value.split(";", 2)
          [ code&.strip, name&.strip ]
        end
      end
  end
end
