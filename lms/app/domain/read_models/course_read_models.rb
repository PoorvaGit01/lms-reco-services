module Domain
  module ReadModels
    class Course < ActiveRecord::Base
      self.table_name = 'view_schema.courses'
      self.primary_key = 'aggregate_id'
      
      has_many :lessons, class_name: 'Domain::ReadModels::Lesson', foreign_key: 'course_id', primary_key: 'aggregate_id'
      has_many :completions, class_name: 'Domain::ReadModels::LessonCompletion', foreign_key: 'course_id'
      
      def completion_percentage(user_id)
        return 0 if lessons.empty?

        completed_count = completions.where(user_id: user_id).select(:lesson_id).distinct.count
        (completed_count.to_f / lessons.count * 100).round(2)
      end
    end

    class Lesson < ActiveRecord::Base
      self.table_name = 'view_schema.lessons'
      self.primary_key = 'aggregate_id'
      
      belongs_to :course, class_name: 'Domain::ReadModels::Course', foreign_key: 'course_id', primary_key: 'aggregate_id'
      has_many :completions, class_name: 'Domain::ReadModels::LessonCompletion', foreign_key: 'lesson_id'
      
      def completed_by?(user_id)
        completions.exists?(user_id: user_id)
      end
    end

    class LessonCompletion < ActiveRecord::Base
      self.table_name = 'view_schema.lesson_completions'
      
      belongs_to :course, class_name: 'Domain::ReadModels::Course', foreign_key: 'course_id', primary_key: 'aggregate_id'
      belongs_to :lesson, class_name: 'Domain::ReadModels::Lesson', foreign_key: 'lesson_id', primary_key: 'aggregate_id'
    end
  end
end
