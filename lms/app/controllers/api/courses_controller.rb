# frozen_string_literal: true

module Api
  class CoursesController < ApplicationController
    before_action :set_course, only: %i[show update destroy]

    def index
      courses = Domain::ReadModels::Course.all
      courses = apply_filters(courses)
      courses = apply_sorting(courses)
      total_count = courses.count
      courses = apply_pagination(courses)

      render json: {
        data:       courses.map { |c| course_json(c) },
        pagination: {
          page:        current_page,
          per_page:    per_page,
          total:       total_count,
          total_pages: (total_count.to_f / per_page).ceil
        }
      }
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

    def apply_filters(courses)
      courses = courses.where("title ILIKE ?", "%#{params[:title]}%") if params[:title].present?
      courses = courses.where(instructor_id: params[:instructor_id]) if params[:instructor_id].present?
      courses
    end

    def apply_sorting(courses)
      sort_by = params[:sort_by] || 'created_at'
      sort_order = params[:sort_order] || 'desc'

      allowed_sort_fields = %w[title created_at instructor_id]
      sort_by = 'created_at' unless allowed_sort_fields.include?(sort_by)
      sort_order = 'desc' unless %w[asc desc].include?(sort_order.downcase)

      courses.order(sort_by => sort_order.downcase.to_sym)
    end

    def apply_pagination(courses)
      offset_value = (current_page - 1) * per_page
      courses.limit(per_page).offset(offset_value)
    end

    def current_page
      page = params[:page].to_i
      page.positive? ? page : 1
    end

    def per_page
      limit = params[:per_page].to_i
      return 20 if limit.zero?

      [limit, 100].min
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
