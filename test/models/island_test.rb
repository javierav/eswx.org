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
end
