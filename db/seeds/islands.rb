# Islas de Baleares y Canarias. El INE las codifica con tres dígitos, de los que los
# dos primeros son la provincia.
#
# Fuente: https://www.ine.es/daco/daco42/codmun/cod_islas.htm
provinces = Province.pluck(:ine_code, :id).to_h

rows = Seeds.csv("islands").map do |row|
  { ine_code: row["ine_code"], name: row["name"],
    province_id: provinces.fetch(row["province_ine_code"]) }
end

Seeds.upsert(Island, rows, :ine_code)
