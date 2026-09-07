# Nivel con el que AEMET agrupa sus zonas de aviso: una provincia, o una isla en
# Baleares y Canarias. Es una construcción suya, no una división administrativa, y su
# código de cuatro dígitos no es del INE.
#
# Fuente: delimitación de zonas del Plan Meteoalerta v6 de AEMET.
provinces = Province.pluck(:ine_code, :id).to_h

rows = Seeds.csv("weather_territories").map do |row|
  { code: row["code"], name: row["name"],
    province_id: provinces.fetch(row["province_ine_code"]) }
end

Seeds.upsert(WeatherTerritory, rows, :code)
