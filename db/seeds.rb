# Datos de referencia territoriales.
#
# Son dos divisiones distintas que se cargan juntas porque una engancha con la otra:
# la administrativa del INE (comunidades, provincias, islas, municipios) y la de AEMET
# para los avisos (territorios y zonas). Sin ellas no se puede colgar ningún aviso de
# su zona, así que no son datos de ejemplo.
#
# Cada fuente vive en db/seeds/ como CSV, con un importador del mismo nombre al lado.
# Las geometrías van aparte, en GeoJSON, porque no caben en una celda. Las dos
# divisiones se enganchan por una sola columna en tres ficheros del INE: el código de
# AEMET en regions, el territorio en islands y la zona de aviso en municipalities. Por
# eso los territorios y las zonas se cargan en medio.
#
# Todo es idempotente: db:seed y db:seed:replant se pueden repetir sin miedo.

require "csv"

module Seeds
  DIR = Rails.root.join("db/seeds")

  # El orden importa: cada fichero resuelve claves ajenas de los anteriores.
  SOURCES = %w[
    regions provinces weather_territories weather_zones islands municipalities
  ].freeze

  class << self
    def load_all
      check_connection!
      ApplicationRecord.transaction { SOURCES.each { |source| load DIR.join("#{source}.rb") } }
      puts summary
    end

    def csv(name) = CSV.read(DIR.join("#{name}.csv"), headers: true)

    def json(name) = JSON.parse(DIR.join("#{name}.geojson").read)

    def upsert(model, rows, key)
      return if rows.empty?

      timestamp = Time.current
      rows = rows.map { |row| row.merge(created_at: timestamp, updated_at: timestamp) }
      model.upsert_all(rows, unique_by: key, update_only: rows.first.keys - [ key, :created_at ])
    end

    private

      # db:drop deja la conexión apuntando a la base de mantenimiento de PostgreSQL,
      # así que encadenar "db:drop db:prepare" en una sola invocación sembraría contra
      # la base equivocada. Mejor plantarse que escribir donde no toca. Se compara con
      # database.yml y no con connection_db_config, porque tras el db:drop la conexión
      # entera apunta a mantenimiento y diría que está justo donde debe.
      def check_connection!
        expected = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first&.database
        actual = ApplicationRecord.connection.select_value("SELECT current_database()")
        return if expected.blank? || actual == expected

        raise "conectado a #{actual} en vez de a #{expected}; usa bin/rails db:reset " \
              "en lugar de encadenar db:drop con db:prepare"
      end

      def summary
        "#{Region.count} comunidades, #{Province.count} provincias, #{Island.count} islas, " \
          "#{WeatherTerritory.count} territorios, #{WeatherZone.count} zonas " \
          "(#{WeatherZone.inland.count} terrestres, #{WeatherZone.offshore.count} costeras), " \
          "#{Municipality.count} municipios " \
          "(#{Municipality.where.not(island_id: nil).count} insulares)"
      end
  end
end

Seeds.load_all
