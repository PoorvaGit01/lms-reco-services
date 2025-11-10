# frozen_string_literal: true

module Domain
  module Projections
    class LearnerHistoryProjection < Sequent::Projector
      manages_tables([])

      on Domain::Events::LessonCompleted do |event|
        LearnerHistoryRecord.create!(
          user_id:      event.user_id,
          lesson_id:    event.lesson_id,
          course_id:    event.course_id,
          completed_at: event.completed_at,
          created_at:   event.created_at
        )
      end
    end

    class LearnerHistoryRecord < ApplicationRecord
      self.table_name = 'view_schema.learner_histories'
    end
  end
end
