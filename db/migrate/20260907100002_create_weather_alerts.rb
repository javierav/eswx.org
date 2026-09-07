# Un registro por mensaje CAP recibido de AEMET. Las filas son inmutables salvo
# superseded_at: el histórico se reconstruye siguiendo las cadenas de Update.
class CreateWeatherAlerts < ActiveRecord::Migration[8.2]
  def change
    create_table :weather_alerts do |t|
      t.string :identifier, null: false
      t.string :msg_type, null: false
      t.string :status, null: false
      t.datetime :sent, null: false
      # No puede llamarse "references": choca con el DSL de las migraciones.
      t.string :referenced_identifiers, null: false, default: ""
      t.datetime :effective, null: false
      t.datetime :onset, null: false
      t.datetime :expires, null: false
      t.string :severity, null: false
      t.string :level, null: false
      t.string :phenomenon_code, null: false
      t.string :phenomenon_name, null: false
      t.string :parameter
      t.string :probability
      t.string :event, null: false
      t.string :headline, null: false
      t.text :description
      t.text :instruction
      t.references :weather_zone, null: false, foreign_key: true
      t.datetime :superseded_at
      t.text :raw_cap, null: false
      t.timestamps

      t.index :identifier, unique: true
      t.index [ :weather_zone_id, :phenomenon_code ]
      t.index :expires
      t.index [ :sent, :superseded_at ]

      t.check_constraint "msg_type IN ('Alert', 'Update')", name: "weather_alerts_msg_type_check"
      t.check_constraint "status IN ('Actual', 'Test')", name: "weather_alerts_status_check"
      t.check_constraint "severity IN ('Moderate', 'Severe', 'Extreme')", name: "weather_alerts_severity_check"
      t.check_constraint "level IN ('amarillo', 'naranja', 'rojo')", name: "weather_alerts_level_check"
      t.check_constraint "expires >= onset", name: "weather_alerts_period_check"
    end
  end
end
