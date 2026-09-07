# Isla del INE. Solo las hay en Baleares y Canarias, y su código de tres dígitos
# empieza por los dos de su provincia.
# https://www.ine.es/daco/daco42/codmun/cod_islas.htm
class Island < ApplicationRecord
  belongs_to :province
  has_one :region, through: :province
  has_many :municipalities, dependent: :restrict_with_exception

  validates :ine_code, presence: true, uniqueness: true, length: { is: 3 }
  validates :name, presence: true

  scope :ordered, -> { order(:name) }

  def to_param = ine_code
end
