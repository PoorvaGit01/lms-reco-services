# frozen_string_literal: true

module Api
  class EventsController < ApplicationController
    def lesson_completed
      event_data = params.require(:event).permit(:user_id, :lesson_id, :course_id, :completed_at, :aggregate_id, :sequence_number, :created_at)

      completed_at = if event_data[:completed_at].is_a?(String)
                       Time.zone.parse(event_data[:completed_at])
                     else
                       event_data[:completed_at] || Time.current
                     end

      created_at = if event_data[:created_at].is_a?(String)
                     Time.zone.parse(event_data[:created_at])
                   else
                     event_data[:created_at] || Time.current
                   end

      record = Domain::Projections::LearnerHistoryRecord.create!(
        user_id:      event_data[:user_id],
        lesson_id:    event_data[:lesson_id],
        course_id:    event_data[:course_id],
        completed_at: completed_at,
        created_at:   created_at
      )

      render json: {
        message:   'Event received and processed',
        event_id:  record.id,
        user_id:   record.user_id,
        lesson_id: record.lesson_id,
        course_id: record.course_id
      }, status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_content
    end
  end
end
