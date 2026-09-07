require "test_helper"

class WeatherAlertsControllerTest < ActionDispatch::IntegrationTest
  test "el índice lista los avisos en vigor" do
    get root_url

    assert_response :success
    assert_select "h1", "Avisos meteorológicos"
    assert_select "li.alert", 2
    assert_select "li.alert--rojo"
  end

  test "el índice pinta el mapa con las zonas terrestres coloreadas" do
    get root_url

    assert_response :success
    assert_select "svg.map path", WeatherZone.inland.count
    assert_select "svg.map path.map__zone--rojo", 1
    assert_select "svg.map path.map__zone--amarillo", 1
  end

  test "el índice se suscribe a las actualizaciones en vivo" do
    get root_url

    assert_select "turbo-cable-stream-source"
  end

  test "el detalle muestra el aviso y su histórico" do
    get weather_alert_url(weather_alerts(:current_red))

    assert_response :success
    assert_select "h1", /lluvias de nivel rojo/i
    # El naranja al que sustituye tiene que salir en el histórico.
    assert_select ".history__item", 2
  end
end
