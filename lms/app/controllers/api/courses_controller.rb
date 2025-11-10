# frozen_string_literal: true

module Api
  class CoursesController < ApplicationController
    before_action :set_course, only: %i[show update destroy]

    def index
      courses = Domain::ReadModels::Course.all
      render json: courses.map { |c| course_json(c) }
    end

    def show
      render json: course_json(@course)
    end

    def create
      command = Domain::Commands::CreateCourse.new(
        aggregate_id:  Sequent.new_uuid,
        title:         params[:title],
        description:   params[:description],
        instructor_id: params[:instructor_id]
      )

      Sequent.command_service.execute_commands(command)

      course = Domain::ReadModels::Course.find(command.aggregate_id)
      render json: course_json(course), status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def update
      command = Domain::Commands::UpdateCourse.new(
        aggregate_id: params[:id],
        title:        params[:title],
        description:  params[:description]
      )

      Sequent.command_service.execute_commands(command)

      course = Domain::ReadModels::Course.find(params[:id])
      render json: course_json(course)
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def destroy
      command = Domain::Commands::DeleteCourse.new(aggregate_id: params[:id])
      Sequent.command_service.execute_commands(command)
      head :no_content
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def set_course
      @course = Domain::ReadModels::Course.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Course not found' }, status: :not_found
    end

    def course_json(course)
      {
        id:                    course.aggregate_id,
        title:                 course.title,
        description:           course.description,
        instructor_id:         course.instructor_id,
        created_at:            course.created_at,
        completion_percentage: params[:user_id] ? course.completion_percentage(params[:user_id]) : nil
      }
    end
  end
end
