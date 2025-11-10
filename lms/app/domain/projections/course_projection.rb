# frozen_string_literal: true

module Domain
  module Projections
    class CourseProjection < Sequent::Projector
      manages_tables(
        CreateViewSchema
      )

      on Domain::Events::CourseCreated do |event|
        CourseRecord.create!(
          aggregate_id:  event.aggregate_id,
          title:         event.title,
          description:   event.description,
          instructor_id: event.instructor_id,
          created_at:    event.created_at
        )
      end

      on Domain::Events::CourseUpdated do |event|
        CourseRecord.where(aggregate_id: event.aggregate_id).update_all(
          title:       event.title,
          description: event.description,
          updated_at:  event.created_at
        )
      end

      on Domain::Events::CourseDeleted do |event|
        CourseRecord.where(aggregate_id: event.aggregate_id).delete_all
      end

      on Domain::Events::LessonCreated do |event|
        LessonRecord.create!(
          aggregate_id: event.aggregate_id,
          course_id:    event.course_id,
          title:        event.title,
          content:      event.content,
          order:        event.order,
          created_at:   event.created_at
        )
      end

      on Domain::Events::LessonUpdated do |event|
        update_hash = {
          updated_at: event.created_at
        }
        update_hash[:title] = event.title if event.title
        update_hash[:content] = event.content if event.content
        update_hash[:order] = event.order if event.order

        LessonRecord.where(aggregate_id: event.aggregate_id).update_all(update_hash)
      end

      on Domain::Events::LessonDeleted do |event|
        LessonRecord.where(aggregate_id: event.aggregate_id).delete_all
      end

      on Domain::Events::LessonCompleted do |event|
        LessonCompletionRecord.create!(
          user_id:      event.user_id,
          lesson_id:    event.lesson_id,
          course_id:    event.course_id,
          completed_at: event.completed_at,
          created_at:   event.created_at
        )
      end
    end

    class CourseRecord < ApplicationRecord
      self.table_name = 'view_schema.courses'
      self.primary_key = 'aggregate_id'
    end

    class LessonRecord < ApplicationRecord
      self.table_name = 'view_schema.lessons'
      self.primary_key = 'aggregate_id'
    end

    class LessonCompletionRecord < ApplicationRecord
      self.table_name = 'view_schema.lesson_completions'
    end
  end
end
