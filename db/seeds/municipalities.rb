# Municipios. Los dos primeros dígitos del código son la provincia; la isla solo la
# tienen los de Baleares y Canarias.
#
# Los nombres van tal cual los publica el INE: artículo pospuesto ("Granjuela, La") y
# forma bilingüe con barra en los 130 que la tienen oficialmente ("Alacant/Alicante").
# Si hace falta mostrarlos en orden natural, es cosa de un helper y no de otra columna.
#
# Fuentes: https://www.ine.es/daco/daco42/codmun/26codmun.xlsx (códigos y nombres) y
#          https://www.ine.es/daco/daco42/codmun/cod_islas.htm (la isla)
provinces = Province.pluck(:ine_code, :id).to_h
islands = Island.pluck(:ine_code, :id).to_h

rows = Seeds.csv("municipalities").map do |row|
  { ine_code: row["ine_code"], name: row["name"],
    normalized_name: Municipality.normalize(row["name"]),
    province_id: provinces.fetch(row["ine_code"].first(2)),
    island_id: islands[row["island_ine_code"]] }
end

Seeds.upsert(Municipality, rows, :ine_code)
