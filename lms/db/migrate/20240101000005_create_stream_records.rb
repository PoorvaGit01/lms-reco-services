class CreateStreamRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :stream_records, id: :uuid do |t|
      t.string :aggregate_id, null: false
      t.string :aggregate_type, null: false
      t.integer :snapshot_threshold, default: 50
      t.timestamp :created_at, null: false
      t.timestamp :updated_at, null: false
    end

    add_index :stream_records, :aggregate_id, unique: true
  end
end

