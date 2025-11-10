class CreateViewSchema < Sequent::Migrations::ViewSchema
  def self.version
    1
  end

  def self.views
    {
      'courses' => %{
        CREATE TABLE view_schema.courses (
          aggregate_id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          instructor_id TEXT NOT NULL,
          created_at TIMESTAMP NOT NULL,
          updated_at TIMESTAMP
        );
      },
      'lessons' => %{
        CREATE TABLE view_schema.lessons (
          aggregate_id TEXT NOT NULL PRIMARY KEY,
          course_id TEXT NOT NULL,
          title TEXT NOT NULL,
          content TEXT,
          "order" INTEGER NOT NULL,
          created_at TIMESTAMP NOT NULL,
          updated_at TIMESTAMP
        );
      },
      'lesson_completions' => %{
        CREATE TABLE view_schema.lesson_completions (
          id SERIAL PRIMARY KEY,
          user_id TEXT NOT NULL,
          lesson_id TEXT NOT NULL,
          course_id TEXT NOT NULL,
          completed_at TIMESTAMP NOT NULL,
          created_at TIMESTAMP NOT NULL
        );
        
        CREATE INDEX idx_lesson_completions_user_id ON view_schema.lesson_completions(user_id);
        CREATE INDEX idx_lesson_completions_lesson_id ON view_schema.lesson_completions(lesson_id);
        CREATE INDEX idx_lesson_completions_course_id ON view_schema.lesson_completions(course_id);
      }
    }
  end

  def self.indexes
    {}
  end
end

