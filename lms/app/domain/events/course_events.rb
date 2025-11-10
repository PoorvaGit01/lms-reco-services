# frozen_string_literal: true

module Domain
  module Events
    class CourseCreated < Sequent::Event
      attrs title: String, description: String, instructor_id: String
    end

    class CourseUpdated < Sequent::Event
      attrs title: String, description: String
    end

    class CourseDeleted < Sequent::Event
    end

    class LessonCreated < Sequent::Event
      attrs course_id: String, title: String, content: String, order: Integer
    end

    class LessonUpdated < Sequent::Event
      attrs title: String, content: String, order: Integer
    end

    class LessonDeleted < Sequent::Event
    end

    class LessonCompleted < Sequent::Event
      attrs user_id: String, lesson_id: String, course_id: String, completed_at: DateTime
    end
  end
end
