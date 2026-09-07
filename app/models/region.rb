# Comunidad o ciudad autónoma, con el código de dos dígitos del INE.
# https://www.ine.es/daco/daco42/codmun/cod_ccaa_provincia.htm
class Region < ApplicationRecord
  CANARY_INE_CODE = "05"

  has_many :provinces, dependent: :restrict_with_exception
  has_many :islands, through: :provinces
  has_many :municipalities, through: :provinces

  validates :ine_code, presence: true, uniqueness: true, length: { is: 2 }
  validates :name, presence: true
  validates :time_zone, presence: true

  scope :ordered, -> { order(:name) }

  # Canarias va una hora por detrás del resto del país, así que cualquier hora hay que
  # mostrarla en la local de su comunidad y no en la del servidor.
  def canary? = ine_code == CANARY_INE_CODE

  def to_param = ine_code
end
