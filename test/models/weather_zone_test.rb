require "test_helper"

class WeatherZoneTest < ActiveSupport::TestCase
  test "encuentra la zona que contiene un punto" do
    assert_equal weather_zones(:pirineo_navarro), WeatherZone.containing(43.0, -1.5)
    assert_equal weather_zones(:campina_gaditana), WeatherZone.containing(36.1, -6.4)
  end

  test "un punto en un agujero queda fuera de la zona" do
    assert_not weather_zones(:campina_gaditana).contains?(36.5, -6.0)
    assert weather_zones(:campina_gaditana).contains?(36.1, -6.4)
  end

  test "no devuelve zonas costeras: se extienden mar adentro y taparían a las terrestres" do
    assert_nil WeatherZone.containing(36.5, -7.0)
  end

  test "devuelve nada si el punto cae fuera de España" do
    assert_nil WeatherZone.containing(51.5, -0.12)
  end

  test "inland y offshore separan las zonas costeras" do
    assert_includes WeatherZone.offshore, weather_zones(:litoral_gaditano)
    assert_not_includes WeatherZone.inland, weather_zones(:litoral_gaditano)
  end
end
