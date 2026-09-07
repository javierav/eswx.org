# Comunidades y ciudades autónomas: 17 comunidades más Ceuta y Melilla.
#
# Llevan los dos códigos porque las dos divisiones las nombran y no se derivan uno del
# otro: coinciden con un desfase de 60 hasta Cataluña, pero AEMET coloca la Comunitat
# Valenciana al final (77) mientras que el INE la pone en el 10, y eso desplaza un
# puesto todo el tramo que va de Extremadura a La Rioja. La correspondencia se verificó
# cruzando los conjuntos de provincias de cada comunidad, no copiándola.
#
# La zona horaria no es un dato del INE, pero hace falta aquí: Canarias va una hora por
# detrás y sin ella no se puede mostrar ninguna hora en la local de cada sitio.
#
# Fuentes: https://www.ine.es/daco/daco42/codmun/cod_ccaa_provincia.htm
#          region_aemet_codes.csv, del shapefile de zonas del Plan Meteoalerta.
aemet_codes = Seeds.csv("region_aemet_codes").to_h { |row| [ row["ine_code"], row["aemet_code"] ] }

rows = Seeds.csv("regions").map do |row|
  { ine_code: row["ine_code"], aemet_code: aemet_codes.fetch(row["ine_code"]),
    name: row["name"], time_zone: row["time_zone"] }
end

Seeds.upsert(Region, rows, :ine_code)
