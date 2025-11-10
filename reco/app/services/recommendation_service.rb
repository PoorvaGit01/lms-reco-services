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

    {
      course_id: 'beginner-course-001',
      title:     'Introduction to Learning',
      reason:    'Recommended for new learners (fallback)'
    }
  end

  def recommend_for_existing_learner(learner_history)
    learner_history.pluck(:course_id).uniq
    recent_course = learner_history.recent.first&.course_id
    begin
      user_stats = LmsClient.get_user_stats(@user_id)
      if user_stats && user_stats['courses'].any?
        incomplete_courses = user_stats['courses'].select { |c| c['completion_percentage'] && c['completion_percentage'] < 100 }
        if incomplete_courses.any?
          course = incomplete_courses.first
          return {
            course_id: course['course_id'],
            title:     course['title'],
            reason:    "Continue your learning - #{course['completion_percentage']}% complete"
          }
        end
      end
    rescue StandardError => e
      Rails.logger.error "Error fetching user stats from LMS: #{e.message}"
    end

    if recent_course
      {
        course_id: "related-to-#{recent_course}",
        title:     'Advanced Course',
        reason:    "Based on your completion of course #{recent_course}"
      }
    else
      {
        course_id: 'popular-course-001',
        title:     'Popular Course',
        reason:    'Recommended based on popular courses'
      }
    end
  end
end
