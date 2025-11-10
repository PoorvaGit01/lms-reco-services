class CreateEventStore < ActiveRecord::Migration[7.2]
  def change
    create_table :event_records, id: :uuid do |t|
      t.string :aggregate_id, null: false
      t.integer :sequence_number, null: false
      t.string :event_type, null: false
      t.jsonb :event_json, null: false
      t.timestamp :created_at, null: false
    end

    add_index :event_records, [:aggregate_id, :sequence_number], unique: true
    add_index :event_records, :created_at
  end
end

