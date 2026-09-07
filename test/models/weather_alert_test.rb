require "test_helper"

class WeatherAlertTest < ActiveSupport::TestCase
  def cap(name) = Aemet::CapMessage.new(file_fixture("aemet/#{name}.xml").read)

  # Importación

  test "importa un aviso y lo cuelga de su zona" do
    assert_difference "WeatherAlert.count", 1 do
      assert WeatherAlert.import(cap("alert"))
    end

    alert = WeatherAlert.find_by(identifier: cap("alert").identifier)
    assert_equal weather_zones(:pirineo_navarro), alert.weather_zone
    assert_equal "amarillo", alert.level
    assert_equal "Temperaturas máximas", alert.phenomenon_name
  end

  test "no guarda dos veces el mismo mensaje" do
    WeatherAlert.import(cap("alert"))

    assert_no_difference "WeatherAlert.count" do
      assert_not WeatherAlert.import(cap("alert"))
    end
  end

  test "descarta los mensajes sin aviso" do
    assert_no_difference "WeatherAlert.count" do
      assert_equal 0, WeatherAlert.import_all([ cap("minor") ])
    end
  end

  test "descarta el mensaje si ni siquiera conoce el territorio" do
    assert_no_difference "WeatherAlert.count" do
      assert_not WeatherAlert.import(cap_for_zone("999999"))
    end
  end

  test "da de alta la zona con el polígono del propio CAP si AEMET publica una nueva" do
    # 7431 es Navarra, que sí existe; la zona 743199 no está en la delimitación v6.
    assert_difference [ "WeatherZone.count", "WeatherAlert.count" ], 1 do
      assert WeatherAlert.import(cap_for_zone("743199"))
    end

    zone = WeatherZone.find_by(code: "743199")
    assert_equal weather_territories(:navarra), zone.weather_territory
    assert zone.svg_path.present?
    assert zone.min_lat < zone.max_lat
  end

  # Sustitución

  test "un Update sustituye al aviso que referencia" do
    WeatherAlert.import_all([ cap("alert"), cap("supersession") ])

    previous = WeatherAlert.find_by(identifier: cap("alert").identifier)
    current = WeatherAlert.find_by(identifier: cap("supersession").identifier)

    assert_equal current.sent, previous.superseded_at
    assert_predicate previous, :superseded?
    assert_predicate current, :active?
  end

  test "sustituye igual aunque el tar.gz traiga los mensajes desordenados" do
    WeatherAlert.import_all([ cap("supersession"), cap("alert") ])

    assert_predicate WeatherAlert.find_by(identifier: cap("alert").identifier), :superseded?
  end

  test "un aviso que llega después de su Update nace ya sustituido" do
    # Cada import es una descarga distinta: el orden no lo arregla la ordenación.
    WeatherAlert.import(cap("supersession"))
    WeatherAlert.import(cap("alert"))

    assert_predicate WeatherAlert.find_by(identifier: cap("alert").identifier), :superseded?
  end

  test "una retirada se guarda y se reconoce como tal" do
    WeatherAlert.import(cap("update"))
    WeatherAlert.import(cap("withdrawal"))

    withdrawal = WeatherAlert.find_by(identifier: cap("withdrawal").identifier)
    assert_predicate withdrawal, :withdrawal?
    assert_equal :withdrawn, withdrawal.state
    assert_predicate WeatherAlert.find_by(identifier: cap("update").identifier), :superseded?
  end

  test "refresh_from_aemet no repite nada al pasar dos veces por el mismo estado" do
    feed = stubbed_feed

    assert_equal 3, WeatherAlert.refresh_from_aemet(feed: feed)
    assert_equal 0, WeatherAlert.refresh_from_aemet(feed: stubbed_feed)
  end

  # Estado

  test "active deja fuera lo caducado y lo sustituido" do
    active = WeatherAlert.active

    assert_includes active, weather_alerts(:active_yellow)
    assert_includes active, weather_alerts(:current_red)
    assert_not_includes active, weather_alerts(:expired)
    assert_not_includes active, weather_alerts(:superseded_orange)
  end

  test "ordena por urgencia y no por hora" do
    zone = weather_zones(:campina_gaditana)

    assert_equal "rojo", zone.weather_alerts.active.by_urgency.first.level
  end

  test "highest_levels_by_zone se queda con el nivel más alto de cada zona" do
    levels = WeatherAlert.highest_levels_by_zone

    assert_equal "rojo", levels[weather_zones(:campina_gaditana).id]
    assert_equal "amarillo", levels[weather_zones(:pirineo_navarro).id]
  end

  # Consultas bitemporales

  test "in_force devuelve lo que se sabía en un instante del pasado" do
    zone = weather_zones(:campina_gaditana)
    orange = weather_alerts(:superseded_orange)
    red = weather_alerts(:current_red)
    moment = 4.hours.ago

    # Hace cuatro horas el naranja seguía siendo la versión buena.
    before = WeatherAlert.in_force(zone, at: moment, known_at: moment)
    assert_includes before, orange
    assert_not_includes before, red

    # Visto desde ahora, para ese mismo instante manda el rojo.
    now = WeatherAlert.in_force(zone, at: moment, known_at: Time.current)
    assert_not_includes now, orange
  end

  test "in_force ignora los avisos que aún no han empezado" do
    assert_not_includes WeatherAlert.in_force(weather_zones(:pirineo_navarro), at: 5.hours.ago),
      weather_alerts(:active_yellow)
  end

  test "history encadena las versiones que cubren un instante" do
    versions = WeatherAlert.history(weather_zones(:campina_gaditana), "PR", at: 2.hours.ago)

    assert_equal [ weather_alerts(:superseded_orange), weather_alerts(:current_red) ], versions.to_a
  end

  test "previous_version y next_version recorren la cadena de Update" do
    assert_equal weather_alerts(:superseded_orange), weather_alerts(:current_red).previous_version
    assert_equal weather_alerts(:current_red), weather_alerts(:superseded_orange).next_version
    assert_nil weather_alerts(:superseded_orange).previous_version
  end

  private

    # Reetiqueta el aviso a otra zona sin tocar el resto del mensaje.
    def cap_for_zone(code)
      xml = file_fixture("aemet/alert.xml").read
        .gsub("<value>743103</value>", "<value>#{code}</value>")
        .gsub("20260906171113.743103", "20260906171113.#{code}")
      Aemet::CapMessage.new(xml)
    end

    def stubbed_feed
      archive = file_fixture("aemet/archive.tar.gz").read
      atom = file_fixture("aemet/feed.atom").read
      feed = Aemet::Feed.new
      feed.define_singleton_method(:get) { |url| url.end_with?(".tar.gz") ? archive : atom }
      feed
    end
end
