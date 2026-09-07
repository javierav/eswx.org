# Estado de los avisos en un instante: lo que pinta el índice y lo que se difunde
# por Turbo cuando llegan avisos nuevos.
#
# Existe para que la vista no consulte por su cuenta: el difusor le pasa un tablero
# ya construido, y así el partial se renderiza igual desde una petición que desde
# el job de refresco.
class WeatherAlertBoard
  attr_reader :at

  def initialize(at: Time.current)
    @at = at
  end

  def alerts
    @alerts ||= WeatherAlert.active(at).by_urgency.includes(weather_zone: { weather_territory: { province: :region } }).to_a
  end

  # Solo las terrestres: las costeras se solapan con el mar y emborronan el mapa.
  def zones
    @zones ||= WeatherZone.inland.order(:code).to_a
  end

  def levels_by_zone
    @levels_by_zone ||= WeatherAlert.highest_levels_by_zone(at: at)
  end

  def level_for(zone) = levels_by_zone[zone.id]

  def counts
    @counts ||= alerts.group_by(&:level).transform_values(&:size)
  end

  def any? = alerts.any?
end
