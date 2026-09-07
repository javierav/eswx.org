# División de AEMET para los avisos, según el Plan Meteoalerta.
#
# No coincide con la administrativa: el territorio es "provincia o isla", y en Baleares
# y Canarias AEMET agrupa por islas con códigos que no son del INE. Al final se
# enganchan las dos divisiones, que es lo único que las relaciona.
class CreateWeatherZones < ActiveRecord::Migration[8.2]
  def change
    create_table :weather_territories do |t|
      t.string :code, limit: 4, null: false
      t.string :name, null: false
      t.references :province, null: false, foreign_key: true
      t.timestamps
      t.index :code, unique: true
    end

    create_table :weather_zones do |t|
      t.string :code, limit: 7, null: false
      t.string :name, null: false
      t.boolean :coastal, null: false, default: false
      t.references :weather_territory, null: false, foreign_key: true
      t.jsonb :geometry, null: false
      t.text :svg_path, null: false
      # Envolvente de la zona. Sin PostGIS no hay índice espacial, así que la búsqueda
      # por punto descarta con estas cuatro columnas antes de recorrer los polígonos
      # en Ruby.
      t.decimal :min_lat, precision: 8, scale: 5, null: false
      t.decimal :max_lat, precision: 8, scale: 5, null: false
      t.decimal :min_lng, precision: 8, scale: 5, null: false
      t.decimal :max_lng, precision: 8, scale: 5, null: false
      t.timestamps
      t.index :code, unique: true
      t.index [ :weather_territory_id, :coastal ]
      t.index [ :min_lat, :max_lat, :min_lng, :max_lng ]
    end

    # AEMET numera las comunidades a su manera y no se deriva del código del INE.
    add_column :regions, :aemet_code, :string, limit: 2, null: false
    add_index :regions, :aemet_code, unique: true

    # Cada isla del INE cae en un territorio de AEMET, pero no al revés: son 11 islas
    # para 10 territorios, porque AEMET fusiona Ibiza y Formentera en uno solo.
    add_reference :islands, :weather_territory, null: false, foreign_key: true

    # La asignación municipio-zona es la definición oficial de cada zona de aviso.
    add_reference :municipalities, :weather_zone, null: false, foreign_key: true
  end
end
