# frozen_string_literal: true

module Api
  class UsersController < ApplicationController
    def next_course
      user_id = params[:id]

      recommendation_service = RecommendationService.new(user_id)
      recommendation = recommendation_service.recommend_next_course

      if recommendation
        render json: {
          user_id:            user_id,
          recommended_course: {
            course_id: recommendation[:course_id],
            title:     recommendation[:title],
            reason:    recommendation[:reason]
          }
        }
      else
        render json: {
          user_id: user_id,
          message: 'No recommendations available at this time'
        }, status: :not_found
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_content
    end
  end
end
