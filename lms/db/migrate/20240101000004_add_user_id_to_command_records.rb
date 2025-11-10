class AddUserIdToCommandRecords < ActiveRecord::Migration[7.2]
  def change
    add_column :command_records, :user_id, :string unless column_exists?(:command_records, :user_id)
    add_index :command_records, :user_id unless index_exists?(:command_records, :user_id)
  end
end

