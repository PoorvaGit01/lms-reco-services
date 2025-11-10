class CreateViewSchema < ActiveRecord::Migration[7.2]
  def up
    execute "CREATE SCHEMA IF NOT EXISTS view_schema"
    
    create_table "view_schema.courses", id: false, force: :cascade do |t|
      t.string "aggregate_id", null: false, primary_key: true
      t.string "title", null: false
      t.text "description"
      t.string "instructor_id", null: false
      t.timestamp "created_at", null: false
      t.timestamp "updated_at"
    end

    create_table "view_schema.lessons", id: false, force: :cascade do |t|
      t.string "aggregate_id", null: false, primary_key: true
      t.string "course_id", null: false
      t.string "title", null: false
      t.text "content"
      t.integer "order", null: false
      t.timestamp "created_at", null: false
      t.timestamp "updated_at"
    end

    create_table "view_schema.lesson_completions", force: :cascade do |t|
      t.string "user_id", null: false
      t.string "lesson_id", null: false
      t.string "course_id", null: false
      t.timestamp "completed_at", null: false
      t.timestamp "created_at", null: false
    end

    add_index "view_schema.lesson_completions", ["user_id"], name: "idx_lesson_completions_user_id"
    add_index "view_schema.lesson_completions", ["lesson_id"], name: "idx_lesson_completions_lesson_id"
    add_index "view_schema.lesson_completions", ["course_id"], name: "idx_lesson_completions_course_id"
  end

  def down
    drop_table "view_schema.lesson_completions" if table_exists?("view_schema.lesson_completions")
    drop_table "view_schema.lessons" if table_exists?("view_schema.lessons")
    drop_table "view_schema.courses" if table_exists?("view_schema.courses")
    execute "DROP SCHEMA IF EXISTS view_schema"
  end
end

