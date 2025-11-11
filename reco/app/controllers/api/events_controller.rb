# frozen_string_literal: true

module Api
  class EventsController < ApplicationController
    def lesson_completed
      event_data = extract_event_data(params)

      record = Domain::Projections::LearnerHistoryRecord.create!(event_data)

      render_success_response(record)
    rescue StandardError => e
      render_error_response(e)
    end

    private

    def extract_event_data(params)
      permitted = params.require(:event).permit(:user_id, :lesson_id, :course_id, :completed_at, :aggregate_id, :sequence_number, :created_at)
      {
        user_id:      permitted[:user_id],
        lesson_id:    permitted[:lesson_id],
        course_id:    permitted[:course_id],
        completed_at: parse_datetime(permitted[:completed_at]),
        created_at:   parse_datetime(permitted[:created_at])
      }
    end

    def parse_datetime(value)
      return Time.zone.parse(value) if value.is_a?(String)

      value || Time.current
    end

    def render_success_response(record)
      render json: {
        message:   'Event received and processed',
        event_id:  record.id,
        user_id:   record.user_id,
        lesson_id: record.lesson_id,
        course_id: record.course_id
      }, status: :created
    end

    def render_error_response(error)
      render json: { error: error.message }, status: :unprocessable_content
    end
  end
end
