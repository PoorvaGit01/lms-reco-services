# frozen_string_literal: true

module Domain
  module Events
    # This event is consumed from LMS service
    class LessonCompleted < Sequent::Event
      attrs user_id: String, lesson_id: String, course_id: String, completed_at: DateTime
    end
  end
end
