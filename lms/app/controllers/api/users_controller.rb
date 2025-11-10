# frozen_string_literal: true

module Api
  class UsersController < ApplicationController
    def stats
      user_id = params[:id]

      completions = Domain::ReadModels::LessonCompletion.where(user_id: user_id)
      courses = Domain::ReadModels::Course.joins(:completions)
                                          .where('view_schema.lesson_completions.user_id = ?', user_id)
                                          .select('view_schema.courses.*')
                                          .distinct

      total_lessons_completed = completions.select(:lesson_id).distinct.count
      total_courses_enrolled = courses.count

      course_stats = courses.map do |course|
        {
          course_id:             course.aggregate_id,
          title:                 course.title,
          completion_percentage: course.completion_percentage(user_id)
        }
      end

      render json: {
        user_id:                 user_id,
        total_lessons_completed: total_lessons_completed,
        total_courses_enrolled:  total_courses_enrolled,
        courses:                 course_stats
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
