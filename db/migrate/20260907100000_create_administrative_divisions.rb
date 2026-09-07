# División administrativa de España según el INE: comunidades y ciudades autónomas,
# provincias, islas y municipios.
#
# Las islas tienen tabla propia porque el INE las codifica aparte de la provincia,
# con tres dígitos de los que los dos primeros son la provincia:
# https://www.ine.es/daco/daco42/codmun/cod_islas.htm
class CreateAdministrativeDivisions < ActiveRecord::Migration[8.2]
  def change
    create_table :regions do |t|
      t.string :ine_code, limit: 2, null: false
      t.string :name, null: false
      # No lo dice el INE: Canarias va una hora por detrás del resto del país y hace
      # falta para poder mostrar cualquier hora en la local de cada sitio.
      t.string :time_zone, null: false
      t.timestamps
      t.index :ine_code, unique: true
    end

    create_table :provinces do |t|
      t.string :ine_code, limit: 2, null: false
      t.string :name, null: false
      t.references :region, null: false, foreign_key: true
      t.timestamps
      t.index :ine_code, unique: true
    end

    create_table :islands do |t|
      t.string :ine_code, limit: 3, null: false
      t.string :name, null: false
      t.references :province, null: false, foreign_key: true
      t.timestamps
      t.index :ine_code, unique: true
    end

    create_table :municipalities do |t|
      t.string :ine_code, limit: 5, null: false
      t.string :name, null: false
      # Nombre sin tildes y en minúsculas, para que "malaga" encuentre "Málaga".
      t.string :normalized_name, null: false
      t.references :province, null: false, foreign_key: true
      # Solo los municipios de Baleares y Canarias están en una isla.
      t.references :island, foreign_key: true
      t.timestamps
      t.index :ine_code, unique: true
      t.index :normalized_name
    end
  end
end
