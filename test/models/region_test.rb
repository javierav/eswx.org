require "test_helper"

class RegionTest < ActiveSupport::TestCase
  test "guarda los dos códigos, que no se derivan uno del otro" do
    andalucia = regions(:andalucia)

    assert_equal "01", andalucia.ine_code
    assert_equal "61", andalucia.aemet_code
  end

  test "solo Canarias necesita su propia zona horaria" do
    assert_predicate regions(:canarias), :canary?
    assert_equal "Atlantic/Canary", regions(:canarias).time_zone
    assert_not_predicate regions(:andalucia), :canary?
  end

  test "llega a sus islas y municipios a través de las provincias" do
    assert_includes regions(:baleares).islands, islands(:ibiza)
    assert_includes regions(:andalucia).municipalities, municipalities(:jerez)
  end

  test "llega a las zonas de aviso atravesando provincias y territorios" do
    assert_includes regions(:andalucia).weather_zones, weather_zones(:campina_gaditana)
  end
end
