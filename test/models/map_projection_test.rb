require "test_helper"

class MapProjectionTest < ActiveSupport::TestCase
  test "la longitud crece hacia la derecha y la latitud hacia abajo" do
    west = MapProjection.project(-6.0, 40.0, false)
    east = MapProjection.project(0.0, 40.0, false)
    north = MapProjection.project(-3.7, 43.0, false)
    south = MapProjection.project(-3.7, 37.0, false)

    assert west.first < east.first
    assert north.last < south.last
  end

  test "Canarias se traslada al recuadro y cae dentro del lienzo" do
    real = MapProjection.project(-15.5, 28.0, false)
    inset = MapProjection.project(-15.5, 28.0, true)

    assert_not MapProjection.inside_view_box?(*real), "sin trasladar se sale del lienzo"
    assert MapProjection.inside_view_box?(*inset)
  end

  test "la península entra en el lienzo" do
    [ [ -9.3, 43.8 ], [ 3.3, 42.4 ], [ -5.6, 36.0 ], [ 4.3, 39.9 ] ].each do |lng, lat|
      assert MapProjection.inside_view_box?(*MapProjection.project(lng, lat, false)),
        "#{lng},#{lat} se sale del lienzo"
    end
  end

  test "genera un camino cerrado por cada anillo" do
    geometry = { "type" => "Polygon",
                 "coordinates" => [ [ [ -3.0, 40.0 ], [ -2.0, 40.0 ], [ -2.0, 41.0 ], [ -3.0, 40.0 ] ] ] }
    path = MapProjection.path(geometry)

    assert path.start_with?("M")
    assert path.end_with?("Z")
    assert_equal 1, path.count("M")
  end

  test "calcula la envolvente de una geometría" do
    bounds = MapProjection.bounds(weather_zones(:pirineo_navarro).geometry)

    assert_in_delta 42.5, bounds[:min_lat], 0.001
    assert_in_delta(-1.0, bounds[:max_lng], 0.001)
  end
end
