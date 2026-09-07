# Municipios. Los dos primeros dígitos del código son la provincia; la isla solo la
# tienen los de Baleares y Canarias.
#
# Los nombres van tal cual los publica el INE: artículo pospuesto ("Granjuela, La") y
# forma bilingüe con barra en los 130 que la tienen oficialmente ("Alacant/Alicante").
# Si hace falta mostrarlos en orden natural, es cosa de un helper y no de otra columna.
#
# La zona de aviso es la definición oficial que da el Plan Meteoalerta de una zona: una
# agrupación de municipios. Por eso buscar por municipio es exacto, mientras que buscar
# por punto solo puede aproximarlo sobre polígonos generalizados. Las zonas costeras no
# aparecen: un municipio pertenece a una única zona terrestre.
#
# Fuentes: https://www.ine.es/daco/daco42/codmun/26codmun.xlsx (códigos y nombres),
#          https://www.ine.es/daco/daco42/codmun/cod_islas.htm (la isla) y
#          municipality_weather_zones.csv (la zona de aviso).
provinces = Province.pluck(:ine_code, :id).to_h
islands = Island.pluck(:ine_code, :id).to_h
zones = WeatherZone.pluck(:code, :id).to_h
zone_of = Seeds.csv("municipality_weather_zones")
  .to_h { |row| [ row["ine_code"], row["weather_zone_code"] ] }

rows = Seeds.csv("municipalities").map do |row|
  { ine_code: row["ine_code"], name: row["name"],
    normalized_name: Municipality.normalize(row["name"]),
    province_id: provinces.fetch(row["ine_code"].first(2)),
    island_id: islands[row["island_ine_code"]],
    weather_zone_id: zones.fetch(zone_of.fetch(row["ine_code"])) }
end

Seeds.upsert(Municipality, rows, :ine_code)
