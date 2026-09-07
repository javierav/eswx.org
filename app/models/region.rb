# Comunidad o ciudad autónoma. Lleva los dos códigos porque las dos divisiones la
# nombran y no se derivan uno del otro: el del INE (01 a 19) y el de AEMET (61 a 79).
# https://www.ine.es/daco/daco42/codmun/cod_ccaa_provincia.htm
class Region < ApplicationRecord
  CANARY_INE_CODE = "05"

  has_many :provinces, dependent: :restrict_with_exception
  has_many :islands, through: :provinces
  has_many :municipalities, through: :provinces
  has_many :weather_territories, through: :provinces
  has_many :weather_zones, through: :weather_territories

  validates :ine_code, presence: true, uniqueness: true, length: { is: 2 }
  validates :aemet_code, presence: true, uniqueness: true, length: { is: 2 }
  validates :name, presence: true
  validates :time_zone, presence: true

  scope :ordered, -> { order(:name) }

  # Canarias va una hora por detrás del resto del país, así que cualquier hora hay que
  # mostrarla en la local de su comunidad y no en la del servidor.
  def canary? = ine_code == CANARY_INE_CODE

  def to_param = ine_code
end
