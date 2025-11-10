class CreateViewSchema < ActiveRecord::Migration[7.2]
  def up
    execute "CREATE SCHEMA IF NOT EXISTS view_schema"
    
    create_table "view_schema.learner_histories", force: :cascade do |t|
      t.string "user_id", null: false
      t.string "lesson_id", null: false
      t.string "course_id", null: false
      t.timestamp "completed_at", null: false
      t.timestamp "created_at", null: false
    end

    add_index "view_schema.learner_histories", ["user_id"], name: "idx_learner_histories_user_id"
    add_index "view_schema.learner_histories", ["course_id"], name: "idx_learner_histories_course_id"
    add_index "view_schema.learner_histories", ["completed_at"], name: "idx_learner_histories_completed_at"
  end

  def down
    drop_table "view_schema.learner_histories" if table_exists?("view_schema.learner_histories")
    execute "DROP SCHEMA IF EXISTS view_schema"
  end
end

