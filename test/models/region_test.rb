require "test_helper"

class RegionTest < ActiveSupport::TestCase
  test "solo Canarias necesita su propia zona horaria" do
    assert_predicate regions(:canarias), :canary?
    assert_equal "Atlantic/Canary", regions(:canarias).time_zone
    assert_not_predicate regions(:andalucia), :canary?
  end

  test "llega a sus islas y municipios a través de las provincias" do
    assert_includes regions(:baleares).islands, islands(:ibiza)
    assert_includes regions(:andalucia).municipalities, municipalities(:jerez)
  end
end
