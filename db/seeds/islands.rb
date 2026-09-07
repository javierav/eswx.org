# Islas de Baleares y Canarias. El INE las codifica con tres dígitos, de los que los
# dos primeros son la provincia.
#
# Cada una cae en un único territorio de AEMET, pero no al revés: son 11 islas para 10
# territorios, porque AEMET fusiona Ibiza y Formentera en uno solo. Esa correspondencia
# es el único puente hecho a mano entre las dos divisiones, precisamente porque es donde
# no coinciden.
#
# Fuentes: https://www.ine.es/daco/daco42/codmun/cod_islas.htm
#          island_weather_territories.csv, hecho a mano.
provinces = Province.pluck(:ine_code, :id).to_h
territories = WeatherTerritory.pluck(:code, :id).to_h
territory_of = Seeds.csv("island_weather_territories")
  .to_h { |row| [ row["ine_code"], row["weather_territory_code"] ] }

rows = Seeds.csv("islands").map do |row|
  { ine_code: row["ine_code"], name: row["name"],
    province_id: provinces.fetch(row["province_ine_code"]),
    weather_territory_id: territories.fetch(territory_of.fetch(row["ine_code"])) }
end

Seeds.upsert(Island, rows, :ine_code)
