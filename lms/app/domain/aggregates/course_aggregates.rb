# frozen_string_literal: true

module Domain
  module Aggregates
    class Course < Sequent::AggregateRoot
      def initialize(command)
        super(command.aggregate_id)
        apply Domain::Events::CourseCreated,
              title:         command.title,
              description:   command.description,
              instructor_id: command.instructor_id
      end

      def update(command)
        apply Domain::Events::CourseUpdated,
              title:       command.title,
              description: command.description
      end

      def delete
        apply Domain::Events::CourseDeleted
      end

      on Domain::Events::CourseCreated do |event|
        @title = event.title
        @description = event.description
        @instructor_id = event.instructor_id
      end

      on Domain::Events::CourseUpdated do |event|
        @title = event.title if event.title
        @description = event.description if event.description
      end

      on Domain::Events::CourseDeleted do |_event|
        @deleted = true
      end
    end

    class Lesson < Sequent::AggregateRoot
      def initialize(command)
        super(command.aggregate_id)
        apply Domain::Events::LessonCreated,
              course_id: command.course_id,
              title:     command.title,
              content:   command.content,
              order:     command.order
      end

      def update(command)
        apply Domain::Events::LessonUpdated,
              title:   command.title,
              content: command.content,
              order:   command.order
      end

      def delete
        apply Domain::Events::LessonDeleted
      end

      def complete(user_id)
        apply Domain::Events::LessonCompleted,
              user_id:      user_id,
              lesson_id:    id,
              course_id:    @course_id,
              completed_at: Time.current
      end

      on Domain::Events::LessonCreated do |event|
        @course_id = event.course_id
        @title = event.title
        @content = event.content
        @order = event.order
      end

      on Domain::Events::LessonUpdated do |event|
        @title = event.title if event.title
        @content = event.content if event.content
        @order = event.order if event.order
      end

      on Domain::Events::LessonDeleted do |_event|
        @deleted = true
      end

      on Domain::Events::LessonCompleted do |_event|
        @completed = true
      end
    end
  end
end
