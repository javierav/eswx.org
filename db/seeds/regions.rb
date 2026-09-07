# Comunidades y ciudades autónomas: 17 comunidades más Ceuta y Melilla.
#
# La zona horaria no es un dato del INE, pero hace falta aquí: Canarias va una hora por
# detrás y sin ella no se puede mostrar ninguna hora en la local de cada sitio.
#
# Fuente: https://www.ine.es/daco/daco42/codmun/cod_ccaa_provincia.htm
rows = Seeds.csv("regions").map do |row|
  { ine_code: row["ine_code"], name: row["name"], time_zone: row["time_zone"] }
end

Seeds.upsert(Region, rows, :ine_code)
