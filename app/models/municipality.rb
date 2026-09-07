# Municipio del INE. Los dos primeros dígitos de su código son la provincia.
class Municipality < ApplicationRecord
  belongs_to :province
  # Solo los municipios de Baleares y Canarias están en una isla.
  belongs_to :island, optional: true
  has_one :region, through: :province

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
