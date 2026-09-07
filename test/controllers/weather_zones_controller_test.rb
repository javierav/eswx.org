require "test_helper"

class WeatherZonesControllerTest < ActionDispatch::IntegrationTest
  test "la zona muestra sus avisos y sus municipios" do
    get weather_zone_url(weather_zones(:campina_gaditana))

    assert_response :success
    assert_select "h1", "Campiña gaditana"
    assert_select "li.alert", 1
    assert_select ".municipalities li", 2
  end

  test "un punto lleva a la zona que lo contiene" do
    get weather_zones_url(lat: 43.0, lng: -1.5)

    assert_redirected_to weather_zone_url(weather_zones(:pirineo_navarro))
  end

  test "un punto fuera de España cae en el listado, avisando" do
    get weather_zones_url(lat: 51.5, lng: -0.12)

    assert_response :success
    assert_select ".notice"
  end

  test "sin coordenadas lista las zonas terrestres" do
    get weather_zones_url

    assert_response :success
    assert_select ".zones li", WeatherZone.inland.count
  end

  test "unas coordenadas ilegibles no revientan" do
    get weather_zones_url(lat: "arriba", lng: "a la izquierda")

    assert_response :success
  end
end
