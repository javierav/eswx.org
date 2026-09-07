# Datos de referencia: la división administrativa de España según el INE.
#
# No son datos de ejemplo. Comunidades, provincias, islas y municipios son la base
# sobre la que se apoya todo lo demás, así que se cargan siempre.
#
# Cada fuente vive en db/seeds/ como CSV, con un importador del mismo nombre al lado.
# Todo es idempotente: db:seed y db:seed:replant se pueden repetir sin miedo.

require "csv"

module Seeds
  DIR = Rails.root.join("db/seeds")

  # El orden importa: cada fichero resuelve claves ajenas de los anteriores.
  SOURCES = %w[regions provinces islands municipalities].freeze

  class << self
    def load_all
      check_connection!
      ApplicationRecord.transaction { SOURCES.each { |source| load DIR.join("#{source}.rb") } }
      puts summary
    end

    def csv(name) = CSV.read(DIR.join("#{name}.csv"), headers: true)

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
          "#{Municipality.count} municipios " \
          "(#{Municipality.where.not(island_id: nil).count} insulares)"
      end
  end
end

Seeds.load_all
