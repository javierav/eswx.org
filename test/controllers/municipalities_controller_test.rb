require "test_helper"

class MunicipalitiesControllerTest < ActionDispatch::IntegrationTest
  test "el buscador encuentra el municipio sin tildes" do
    get municipalities_url(q: "alcala")

    assert_response :success
    assert_select ".municipalities li", 1
  end

  test "avisa cuando no hay resultados" do
    get municipalities_url(q: "villarriba")

    assert_response :success
    assert_select ".municipalities li", 0
  end

  test "sin búsqueda solo muestra el formulario" do
    get municipalities_url

    assert_response :success
    assert_select "form.search"
    assert_select ".municipalities", 0
  end

  test "el municipio muestra los avisos de su zona" do
    get municipality_url(municipalities(:jerez))

    assert_response :success
    assert_select "h1", "Jerez de la Frontera"
    assert_select "li.alert", 1
  end
end
