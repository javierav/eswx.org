# Zona de aviso del Plan Meteoalerta. Es la unidad sobre la que AEMET emite.
#
# Las zonas costeras llevan una C al final del código y comparten los seis primeros
# dígitos con la zona terrestre correspondiente; se extienden 20 millas náuticas
# mar adentro, así que se excluyen del mapa general y de la búsqueda por punto.
class WeatherZone < ApplicationRecord
  belongs_to :weather_territory
  has_one :province, through: :weather_territory
  has_many :municipalities, dependent: :restrict_with_exception
  has_many :weather_alerts, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :inland, -> { where(coastal: false) }
  scope :offshore, -> { where(coastal: true) }
  scope :ordered, -> { order(:name) }

  # Descarta por envolvente en SQL y solo entonces recorre los polígonos, que es
  # lo más parecido a un índice espacial que hay sin PostGIS.
  def self.containing(lat, lng)
    inland
      .where("min_lat <= :lat AND max_lat >= :lat AND min_lng <= :lng AND max_lng >= :lng", lat:, lng:)
      .find { |zone| zone.contains?(lat, lng) }
  end

  def contains?(lat, lng)
    MapProjection.polygons(geometry).any? do |rings|
      outer, *holes = rings
      ring_contains?(outer, lat, lng) && holes.none? { |hole| ring_contains?(hole, lat, lng) }
    end
  end

  def region = weather_territory.province.region

  def to_param = code

  private

    # Lanzamiento de rayo. El anillo viene en GeoJSON, es decir [lng, lat].
    def ring_contains?(ring, lat, lng)
      inside = false
      ring.each_cons(2) do |(lng1, lat1), (lng2, lat2)|
        next unless (lat1 > lat) != (lat2 > lat)

        crossing = (lng2 - lng1) * (lat - lat1) / (lat2 - lat1) + lng1
        inside = !inside if lng < crossing
      end
      inside
    end
end
