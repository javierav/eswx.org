# Un aviso de fenómeno meteorológico adverso, tal y como lo emitió AEMET.
#
# Cada fila es un mensaje CAP y no se modifica nunca salvo para anotar cuándo dejó
# de ser la versión buena. Eso da dos ejes de tiempo:
#
#   vigencia     onset .. expires         para cuándo aplica el aviso
#   conocimiento sent  .. superseded_at   desde cuándo AEMET lo dio por bueno
#
# Así, si a las 19:00 AEMET sube una zona de naranja a rojo, quedan las dos filas:
# ambas cubren las 15:00 en vigencia, y cuál era la verdad depende de a qué hora
# preguntes. Es lo que permite reconstruir el histórico en vez de solo el presente.
class WeatherAlert < ApplicationRecord
  include Importing

  LEVELS = %w[amarillo naranja rojo].freeze
  LEVEL_ORDER = Arel.sql("CASE level WHEN 'rojo' THEN 0 WHEN 'naranja' THEN 1 ELSE 2 END")

  belongs_to :weather_zone
  has_one :weather_territory, through: :weather_zone

  validates :identifier, presence: true, uniqueness: true
  validates :level, inclusion: { in: LEVELS }
  validates :phenomenon_code, presence: true

  scope :actual, -> { where(status: "Actual") }
  scope :current, -> { where(superseded_at: nil) }
  scope :unexpired, ->(at = Time.current) { where(expires: at..) }
  scope :active, ->(at = Time.current) { actual.current.unexpired(at) }
  scope :by_urgency, -> { order(LEVEL_ORDER, :onset) }

  # Avisos vigentes en un instante según lo que se sabía en otro. Con known_at en
  # el pasado se reconstruye lo que se veía entonces.
  def self.in_force(zone, at: Time.current, known_at: Time.current)
    actual
      .where(weather_zone: zone)
      .where(sent: ..known_at)
      .where("superseded_at IS NULL OR superseded_at > :known_at", known_at: known_at)
      .where(onset: ..at, expires: at..)
      .by_urgency
  end

  # Todas las versiones que han cubierto un instante para un fenómeno, ordenadas
  # por emisión: la línea temporal "amarillo, naranja, rojo, retirado".
  def self.history(zone, phenomenon_code, at: Time.current)
    scope = where(weather_zone: zone, phenomenon_code: phenomenon_code)
    covering = scope.where(onset: ..at, expires: at..)
    identifiers = covering.pluck(:identifier)
    return covering.order(:sent) if identifiers.empty?

    # Las retiradas expiran en el momento de enviarse, así que no cubren ningún
    # instante: se recuperan por referenciar a alguna de las versiones anteriores.
    patterns = identifiers.map { |identifier| "%#{sanitize_sql_like(identifier)}%" }
    withdrawals = scope.where(
      Array.new(identifiers.size, "referenced_identifiers LIKE ?").join(" OR "), *patterns
    )
    scope.where(id: covering).or(scope.where(id: withdrawals)).order(:sent)
  end

  def self.highest_levels_by_zone(at: Time.current)
    active(at).pluck(:weather_zone_id, :level).group_by(&:first).transform_values do |pairs|
      pairs.map(&:last).max_by { |level| LEVELS.index(level) }
    end
  end

  def referenced_identifier_list = referenced_identifiers.to_s.split

  def previous_versions
    return self.class.none if referenced_identifier_list.empty?

    self.class.where(identifier: referenced_identifier_list).order(:sent)
  end

  def previous_version = previous_versions.last

  def next_version
    self.class
      .where("referenced_identifiers LIKE ?", "%#{self.class.sanitize_sql_like(identifier)}%")
      .order(:sent)
      .first
  end

  def superseded? = superseded_at.present?
  def expired?(at = Time.current) = expires <= at
  def active?(at = Time.current) = !superseded? && !expired?(at)

  # AEMET no implementa Cancel: retira un aviso con un Update que expira al enviarse.
  def withdrawal? = expires <= sent

  def state
    return :withdrawn if withdrawal?
    return :superseded if superseded?
    return :expired if expired?

    :active
  end

  def region = weather_zone.weather_territory.province.region

  # Canarias va una hora por detrás, así que las horas se muestran en la hora local
  # de la zona avisada y no en la del servidor.
  def local_time_zone = region.time_zone
end
