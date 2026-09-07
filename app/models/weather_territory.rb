# Nivel con el que AEMET agrupa sus zonas de aviso: una provincia, o una isla en
# Baleares y Canarias. Es una construcción suya, no una división administrativa, y su
# código de cuatro dígitos no es del INE.
class WeatherTerritory < ApplicationRecord
  belongs_to :province
  has_one :region, through: :province
  has_many :islands, dependent: :restrict_with_exception
  has_many :weather_zones, dependent: :restrict_with_exception
  has_many :municipalities, through: :weather_zones

  validates :code, presence: true, uniqueness: true, length: { is: 4 }
  validates :name, presence: true

  scope :ordered, -> { order(:name) }

  def island? = islands.any?

  def to_param = code
end
