# frozen_string_literal: true

class RecommendationService
  def initialize(user_id)
    @user_id = user_id
  end

  def recommend_next_course
    learner_history = Domain::ReadModels::LearnerHistory.for_user(@user_id)
    if learner_history.empty?
      recommend_for_new_learner
    else
      recommend_for_existing_learner(learner_history)
    end
  end

  private

  def recommend_for_new_learner
    begin
      courses = LmsClient.get_courses
      if courses&.any?
        # Strategy: Pick first course from LMS for new learners
        # Why first course?
        # - New users don't have preferences yet, any course is better than none
        course = courses.first
        return {
          course_id: course['id'],
          title:     course['title'],
          reason:    'Recommended for new learners - first available course from LMS'
        }
      end
    rescue StandardError => e
      Rails.logger.error "Error fetching courses from LMS: #{e.message}"
    end

    # Fallback: Always return something so API never fails
    # Values come from config, can be overridden via environment variables
    fallback_config = Rails.application.config.recommendations[:new_learner]
    {
      course_id: fallback_config[:course_id],
      title:     fallback_config[:title],
      reason:    fallback_config[:reason]
    }
  end

  def recommend_for_existing_learner(learner_history)
    recent_course = learner_history.recent.first&.course_id

    recommendation = fetch_incomplete_course_recommendation
    return recommendation if recommendation.present?

    build_fallback_recommendation(recent_course)
  end

  def fetch_incomplete_course_recommendation
    user_stats = LmsClient.get_user_stats(@user_id)
    return unless user_stats && user_stats['courses'].any?

    incomplete_courses = user_stats['courses'].select do |course|
      course['completion_percentage'] && course['completion_percentage'] < 100
    end

    return if incomplete_courses.blank?

    # Strategy: Pick first incomplete course to encourage completion
    # Why first incomplete course?
    # - Learners should finish what they started before starting new courses
    # - Improves course completion rates and Maintains learning continuity
    course = incomplete_courses.first
    {
      course_id: course['course_id'],
      title:     course['title'],
      reason:    "Continue your learning - #{course['completion_percentage']}% complete"
    }
  rescue StandardError => e
    Rails.logger.error "Error fetching user stats from LMS: #{e.message}"
    nil
  end

  def build_fallback_recommendation(recent_course)
    # Fallback when LMS fails or all courses are complete
    # Uses recent course to suggest next step, or generic popular course from config
    if recent_course
      {
        course_id: "related-to-#{recent_course}",
        title:     'Advanced Course',
        reason:    "Based on your completion of course #{recent_course}"
      }
    else
      fallback = Rails.application.config.recommendations[:existing_learner]
      {
        course_id: fallback[:popular_course_id],
        title:     fallback[:popular_course_title],
        reason:    fallback[:reason]
      }
    end
  end
end
