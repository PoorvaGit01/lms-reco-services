# Recommendation Service Configuration
# Fallback course recommendations when LMS is unavailable

Reco::Application.config.recommendations = {
  new_learner: {
    course_id: ENV.fetch('FALLBACK_NEW_LEARNER_COURSE_ID', 'beginner-course-001'),
    title: ENV.fetch('FALLBACK_NEW_LEARNER_COURSE_TITLE', 'Introduction to Learning'),
    reason: 'Recommended for new learners (fallback)'
  },
  existing_learner: {
    popular_course_id: ENV.fetch('FALLBACK_POPULAR_COURSE_ID', 'popular-course-001'),
    popular_course_title: ENV.fetch('FALLBACK_POPULAR_COURSE_TITLE', 'Popular Course'),
    reason: 'Recommended based on popular courses'
  }
}
