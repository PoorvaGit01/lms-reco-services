# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Api
  class LessonsController < ApplicationController
    before_action :set_lesson, only: %i[show update destroy]

    def index
      lessons = Domain::ReadModels::Lesson.all
      lessons = lessons.where(course_id: params[:course_id]) if params[:course_id]
      render json: lessons.map { |l| lesson_json(l) }
    end

    def show
      render json: lesson_json(@lesson)
    end

    def create
      command = Domain::Commands::CreateLesson.new(
        aggregate_id: Sequent.new_uuid,
        course_id:    params[:course_id],
        title:        params[:title],
        content:      params[:content],
        order:        params[:order] || 0
      )

      Sequent.command_service.execute_commands(command)

      lesson = Domain::ReadModels::Lesson.find(command.aggregate_id)
      render json: lesson_json(lesson), status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update
      command = Domain::Commands::UpdateLesson.new(
        aggregate_id: params[:id],
        title:        params[:title],
        content:      params[:content],
        order:        params[:order]
      )

      Sequent.command_service.execute_commands(command)

      lesson = Domain::ReadModels::Lesson.find(params[:id])
      render json: lesson_json(lesson)
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      command = Domain::Commands::DeleteLesson.new(aggregate_id: params[:id])
      Sequent.command_service.execute_commands(command)
      head :no_content
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def complete
      lesson = Domain::ReadModels::Lesson.find(params[:id])
      user_id = params[:user_id] || request.headers['X-User-Id']

      unless user_id
        render json: { error: 'User ID is required' }, status: :bad_request
        return
      end

      command = Domain::Commands::CompleteLesson.new(
        aggregate_id: params[:id],
        user_id:      user_id
      )

      Sequent.command_service.execute_commands(command)

      # Send event to Reco service
      send_lesson_completed_event_to_reco(lesson, user_id)

      render json: { message: 'Lesson completed successfully' }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Lesson not found' }, status: :not_found
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def set_lesson
      @lesson = Domain::ReadModels::Lesson.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Lesson not found' }, status: :not_found
    end

    def lesson_json(lesson)
      {
        id:         lesson.aggregate_id,
        course_id:  lesson.course_id,
        title:      lesson.title,
        content:    lesson.content,
        order:      lesson.order,
        created_at: lesson.created_at
      }
    end

    def send_lesson_completed_event_to_reco(lesson, user_id)
      http = build_http_connection
      request = build_reco_request(lesson, user_id)

      http.request(request)
    end

    def reco_service_url
      host = ENV.fetch('RECO_SERVICE_HOST', 'reco')
      port = ENV.fetch('RECO_SERVICE_PORT', '3000')
      "http://#{host}:#{port}/api/events/lesson_completed"
    end

    def build_http_connection
      uri = URI(reco_service_url)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.read_timeout = 5
        http.open_timeout = 5
      end
    end

    def build_reco_request(lesson, user_id)
      uri = URI(reco_service_url)
      event_data = {
        event: {
          user_id:      user_id,
          lesson_id:    lesson.aggregate_id,
          course_id:    lesson.course_id,
          completed_at: Time.current.utc.iso8601
        }
      }

      Net::HTTP::Post.new(uri.path).tap do |request|
        request['Content-Type'] = 'application/json'
        request['Host'] = uri.host
        request.body = event_data.to_json
      end
    end
  end
end
