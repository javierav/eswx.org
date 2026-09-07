# Municipio del INE, con la zona de aviso que le asigna AEMET.
#
# Esa asignación es la definición oficial de cada zona, así que es la vía preferente
# para consultar avisos: buscar por punto solo puede aproximarla sobre polígonos
# generalizados. Los dos primeros dígitos del código son la provincia.
class Municipality < ApplicationRecord
  belongs_to :province
  # Solo los municipios de Baleares y Canarias están en una isla.
  belongs_to :island, optional: true
  belongs_to :weather_zone
  has_one :region, through: :province
  has_one :weather_territory, through: :weather_zone
  has_many :weather_alerts, through: :weather_zone

  validates :ine_code, presence: true, uniqueness: true, length: { is: 5 }
  validates :name, presence: true

  before_validation { self.normalized_name = self.class.normalize(name) }

  scope :ordered, -> { order(:name) }
  scope :search, ->(term) {
    normalized = normalize(term.to_s)
    normalized.present? ? where("normalized_name LIKE ?", "%#{sanitize_sql_like(normalized)}%").ordered : none
  }

  # Sin tildes y en minúsculas: el buscador no debe exigir escribir "Málaga".
  def self.normalize(value)
    value.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.strip
  end

  def to_param = ine_code
end
