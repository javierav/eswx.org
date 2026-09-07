# Zonas de aviso del Plan Meteoalerta: 182 terrestres y 51 costeras.
#
# Los atributos van en el CSV y las geometrías en el GeoJSON de al lado, unidas por el
# código de zona. El camino del SVG y la envolvente se calculan aquí porque son datos
# derivados, no fuente.
#
# Fuente: delimitación de zonas del Plan Meteoalerta v6 de AEMET, reproyectada de
# EPSG:32630 a WGS84 y simplificada a 500 m.
# Obra derivada de BDLJE 2017-02-28 CC-BY ign.es (c) Instituto Geográfico Nacional.
territories = WeatherTerritory.joins(province: :region)
  .pluck(:code, :id, "regions.ine_code")
  .to_h { |code, id, region| [ code, [ id, region == Region::CANARY_INE_CODE ] ] }

geometries = Seeds.json("weather_zones")["features"]
  .to_h { |feature| [ feature["properties"]["code"], feature["geometry"] ] }

outside = []
rows = Seeds.csv("weather_zones").map do |row|
  geometry = geometries.fetch(row["code"])
  territory_id, canary = territories.fetch(row["weather_territory_code"])
  # Si algún día AEMET publica una delimitación nueva puede no caber en el lienzo.
  inside = MapProjection.polygons(geometry).flatten(2).all? do |lng, lat|
    MapProjection.inside_view_box?(*MapProjection.project(lng, lat, canary))
  end
  outside << row["code"] unless inside

  { code: row["code"], name: row["name"], coastal: row["coastal"] == "true",
    weather_territory_id: territory_id, geometry: geometry,
    svg_path: MapProjection.path(geometry, canary: canary),
    **MapProjection.bounds(geometry) }
end

warn "zonas fuera del lienzo del mapa: #{outside.join(', ')}" if outside.any?
Seeds.upsert(WeatherZone, rows, :code)
