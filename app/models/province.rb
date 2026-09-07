# Provincia del INE. En Baleares y Canarias contiene islas, que el INE codifica aparte.
class Province < ApplicationRecord
  belongs_to :region
  has_many :islands, dependent: :restrict_with_exception
  has_many :municipalities, dependent: :restrict_with_exception
  has_many :weather_territories, dependent: :restrict_with_exception
  has_many :weather_zones, through: :weather_territories

  validates :ine_code, presence: true, uniqueness: true, length: { is: 2 }
  validates :name, presence: true

  scope :ordered, -> { order(:name) }

  def to_param = ine_code
end
