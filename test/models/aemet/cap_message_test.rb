require "test_helper"

class Aemet::CapMessageTest < ActiveSupport::TestCase
  def cap(name) = Aemet::CapMessage.new(file_fixture("aemet/#{name}.xml").read)

  test "lee los campos de un aviso" do
    message = cap("alert")

    assert_equal "Alert", message.msg_type
    assert_equal "Actual", message.status
    assert_equal "743103", message.zone_code
    assert_equal "Pirineo navarro", message.zone_name
    assert_equal "amarillo", message.level
    assert_equal "AT", message.phenomenon_code
    assert_equal "Temperaturas máximas", message.phenomenon_name
    assert_equal "40%-70%", message.probability
    assert_equal "Temperatura máxima: 34 ºC", message.parameter_description
    assert_empty message.referenced_identifiers
  end

  test "se queda con el bloque en español y no con el inglés" do
    assert_match(/temperaturas máximas/i, cap("alert").event)
  end

  test "interpreta las horas con su desfase y las guarda en UTC" do
    message = cap("alert")

    assert_equal "UTC", message.sent.time_zone.name
    assert message.onset < message.expires
  end

  test "extrae los identificadores referenciados por un Update" do
    message = cap("update")

    assert_equal "Update", message.msg_type
    assert_equal 1, message.referenced_identifiers.size
    # Cada referencia es "emisor,identificador,emisión": solo interesa el del medio.
    assert_match(/\A2\.49\.0\.0\.724\.0\.ES\./, message.referenced_identifiers.first)
  end

  test "reconoce los mensajes sin aviso" do
    assert_predicate cap("minor"), :minor?
    assert_not_predicate cap("alert"), :minor?
  end

  test "reconoce una retirada por expirar en el momento de enviarse" do
    assert_predicate cap("withdrawal"), :withdrawal?
    assert_not_predicate cap("alert"), :withdrawal?
  end

  test "convierte los polígonos del CAP a GeoJSON con las coordenadas invertidas" do
    geometry = cap("alert").geometry

    assert_equal "MultiPolygon", geometry["type"]
    lng, lat = geometry["coordinates"].first.first.first
    # El CAP escribe "lat,lng" y GeoJSON quiere [lng, lat].
    assert_in_delta(-1.5, lng, 1.5)
    assert_in_delta 43.0, lat, 1.5
  end
end
