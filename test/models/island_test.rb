require "test_helper"

class IslandTest < ActiveSupport::TestCase
  test "el código de isla empieza por el de su provincia" do
    Island.all.each do |island|
      assert_equal island.province.ine_code, island.ine_code.first(2), island.name
    end
  end

  test "solo los municipios insulares tienen isla" do
    assert_equal islands(:ibiza), municipalities(:sant_antoni).island
    assert_nil municipalities(:jerez).island
  end

  test "el municipio y su isla están en la misma provincia" do
    Municipality.where.not(island_id: nil).each do |municipality|
      assert_equal municipality.island.province, municipality.province, municipality.name
    end
  end

  test "varias islas del INE pueden caer en un mismo territorio de AEMET" do
    territory = weather_territories(:ibiza_formentera)

    assert_equal [ islands(:formentera), islands(:ibiza) ], territory.islands.ordered.to_a
    assert_predicate territory, :island?
  end

  test "un territorio que es una provincia no tiene islas" do
    assert_not_predicate weather_territories(:navarra), :island?
  end

  test "la isla de un municipio y el territorio de su zona no se contradicen" do
    Municipality.where.not(island_id: nil).each do |municipality|
      assert_equal municipality.island.weather_territory,
        municipality.weather_zone.weather_territory, municipality.name
    end
  end
end
