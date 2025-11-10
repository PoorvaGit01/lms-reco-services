class CreateCommandRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :command_records, id: :uuid do |t|
      t.string :command_type, null: false
      t.jsonb :command_json, null: false
      t.string :aggregate_id
      t.string :user_id
      t.timestamp :created_at, null: false
    end

    add_index :command_records, :aggregate_id
    add_index :command_records, :user_id
    add_index :command_records, :created_at
  end
end

