require "test_helper"

class MunicipalityTest < ActiveSupport::TestCase
  test "encuentra el municipio aunque se escriba sin tildes" do
    assert_includes Municipality.search("alcala"), municipalities(:alcala)
    assert_includes Municipality.search("ALCALÁ"), municipalities(:alcala)
  end

  test "busca por cualquier parte del nombre" do
    assert_includes Municipality.search("frontera"), municipalities(:jerez)
  end

  test "una búsqueda vacía no devuelve nada" do
    assert_empty Municipality.search("")
    assert_empty Municipality.search(nil)
  end

  test "normaliza el nombre al guardarlo" do
    municipality = Municipality.create!(ine_code: "31013", name: "Améscoa Baja",
      province: provinces(:navarra), weather_zone: weather_zones(:pirineo_navarro))

    assert_equal "amescoa baja", municipality.normalized_name
  end

  test "los dos primeros dígitos del código son su provincia" do
    assert_equal "11", municipalities(:jerez).province.ine_code
  end

  test "llega a los avisos a través de su zona" do
    assert_includes municipalities(:jerez).weather_alerts, weather_alerts(:current_red)
  end
end
