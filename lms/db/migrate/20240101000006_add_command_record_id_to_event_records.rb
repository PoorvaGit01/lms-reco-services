class AddCommandRecordIdToEventRecords < ActiveRecord::Migration[7.2]
  def change
    add_column :event_records, :command_record_id, :uuid unless column_exists?(:event_records, :command_record_id)
    add_index :event_records, :command_record_id unless index_exists?(:event_records, :command_record_id)
  end
end

