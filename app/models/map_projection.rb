# Proyección de las zonas a coordenadas SVG.
#
# Equirectangular con paralelo de referencia en los 40 grados, que es lo que hace
# que España se vea con la proporción a la que estamos acostumbrados. Canarias se
# traslada a un recuadro a la izquierda de la península, a la misma escala.
#
# Las constantes salen de medir las zonas reales; el cargador avisa si alguna se
# sale del lienzo, que es lo que pasaría si AEMET publicara una delimitación nueva.
class MapProjection
  STANDARD_PARALLEL = 40.0
  ORIGIN_LONGITUDE = -3.7
  SCALE = 100.0                        # píxeles por grado de latitud
  CANARY_OFFSET = [ 212.5, -778.2 ].freeze
  VIEW_BOX = "-938 -427 1601 933"
  CANARY_INSET = { x: -933, y: 238, width: 439, height: 263 }.freeze

  COSINE = Math.cos(STANDARD_PARALLEL * Math::PI / 180)

  class << self
    # Devuelve el atributo "d" de un <path> para una geometría GeoJSON.
    def path(geometry, canary: false)
      polygons(geometry).map { |rings| rings.map { |ring| subpath(ring, canary) }.join(" ") }.join(" ")
    end

    def bounds(geometry)
      points = polygons(geometry).flatten(1).flatten(1)
      lngs = points.map(&:first)
      lats = points.map(&:last)
      { min_lng: lngs.min, max_lng: lngs.max, min_lat: lats.min, max_lat: lats.max }
    end

    def polygons(geometry)
      geometry["type"] == "Polygon" ? [ geometry["coordinates"] ] : geometry["coordinates"]
    end

    def project(lng, lat, canary)
      x = (lng - ORIGIN_LONGITUDE) * COSINE * SCALE
      y = (STANDARD_PARALLEL - lat) * SCALE
      canary ? [ x + CANARY_OFFSET[0], y + CANARY_OFFSET[1] ] : [ x, y ]
    end

    def inside_view_box?(x, y)
      left, top, width, height = VIEW_BOX.split.map(&:to_f)
      x.between?(left, left + width) && y.between?(top, top + height)
    end

    private

      def subpath(ring, canary)
        commands = ring.map do |lng, lat|
          x, y = project(lng, lat, canary)
          "#{format('%.1f', x)},#{format('%.1f', y)}"
        end
        "M#{commands.first}L#{commands.drop(1).join(' ')}Z"
      end
  end
end
