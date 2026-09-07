# Provincias, con la grafía oficial: Araba/Álava, Alacant/Alicante, A Coruña, Ourense,
# Gipuzkoa, Bizkaia... Ceuta y Melilla también son provincia (51 y 52) además de
# ciudad autónoma.
#
# Fuente: https://www.ine.es/daco/daco42/codmun/cod_ccaa_provincia.htm
regions = Region.pluck(:ine_code, :id).to_h

rows = Seeds.csv("provinces").map do |row|
  { ine_code: row["ine_code"], name: row["name"],
    region_id: regions.fetch(row["region_ine_code"]) }
end

Seeds.upsert(Province, rows, :ine_code)
