# frozen_string_literal: true

module Domain
  module Commands
    class CreateCourse < Sequent::Command
      attrs title: String, description: String, instructor_id: String
      validates_presence_of :title, :instructor_id
    end

    class UpdateCourse < Sequent::Command
      attrs title: String, description: String
    end

    class DeleteCourse < Sequent::Command
    end

    class CreateLesson < Sequent::Command
      attrs course_id: String, title: String, content: String, order: Integer
      validates_presence_of :course_id, :title, :order
    end

    class UpdateLesson < Sequent::Command
      attrs title: String, content: String, order: Integer
    end

    class DeleteLesson < Sequent::Command
    end

    class CompleteLesson < Sequent::Command
      attrs user_id: String
      validates_presence_of :user_id
    end
  end
end
