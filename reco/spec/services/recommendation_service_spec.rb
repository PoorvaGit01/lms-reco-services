require 'rails_helper'

RSpec.describe RecommendationService do
  let(:user_id) { 'user-123' }
  let(:service) { RecommendationService.new(user_id) }

  before do
    Domain::ReadModels::LearnerHistory.delete_all
    Domain::Projections::LearnerHistoryRecord.delete_all
  end

  describe '#recommend_next_course' do
    context 'for new learners (no history)' do
      it 'recommends a beginner course when LMS service returns courses' do
        allow(LmsClient).to receive(:get_courses).and_return([
          { 'id' => 'course-1', 'title' => 'Introduction to Programming' },
          { 'id' => 'course-2', 'title' => 'Advanced Programming' }
        ])

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
        expect(recommendation[:course_id]).to eq('course-1')
        expect(recommendation[:title]).to eq('Introduction to Programming')
        expect(recommendation[:reason]).to include('new learners')
        expect(recommendation[:reason]).to include('first available course from LMS')
      end

      it 'handles course hash with missing title field' do
        allow(LmsClient).to receive(:get_courses).and_return([
          { 'id' => 'course-1' }
        ])

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
        expect(recommendation[:course_id]).to eq('course-1')
        expect(recommendation[:title]).to be_nil
      end

      it 'handles course hash with missing id field' do
        allow(LmsClient).to receive(:get_courses).and_return([
          { 'title' => 'Course Without ID' }
        ])

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
        expect(recommendation[:course_id]).to be_nil
      end

      it 'uses fallback when LMS service returns empty array' do
        allow(LmsClient).to receive(:get_courses).and_return([])

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
        expect(recommendation[:course_id]).to eq('beginner-course-001')
        expect(recommendation[:title]).to eq('Introduction to Learning')
        expect(recommendation[:reason]).to include('fallback')
      end

      it 'uses fallback when LMS service returns nil' do
        allow(LmsClient).to receive(:get_courses).and_return(nil)

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
        expect(recommendation[:course_id]).to eq('beginner-course-001')
        expect(recommendation[:reason]).to include('fallback')
      end

      it 'uses fallback when LMS service raises an error' do
        allow(LmsClient).to receive(:get_courses).and_raise(StandardError.new('Connection failed'))
        allow(Rails.logger).to receive(:error)

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
        expect(recommendation[:course_id]).to eq('beginner-course-001')
        expect(recommendation[:reason]).to include('fallback')
        expect(Rails.logger).to have_received(:error).with(match(/Error fetching courses from LMS/))
      end

      it 'handles LMS service timeout gracefully' do
        allow(LmsClient).to receive(:get_courses).and_raise(Timeout::Error.new('Request timeout'))

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
        expect(recommendation[:course_id]).to eq('beginner-course-001')
      end
    end

    context 'for existing learners (with history)' do
      let(:course_id_1) { 'course-1' }
      let(:course_id_2) { 'course-2' }
      let(:course_id_3) { 'course-3' }

      before do
        Domain::ReadModels::LearnerHistory.create!(
          user_id: user_id,
          lesson_id: 'lesson-1',
          course_id: course_id_1,
          completed_at: 3.days.ago,
          created_at: 3.days.ago
        )
        Domain::ReadModels::LearnerHistory.create!(
          user_id: user_id,
          lesson_id: 'lesson-2',
          course_id: course_id_2,
          completed_at: 1.day.ago,
          created_at: 1.day.ago
        )
      end

      context 'when LMS service returns user stats with incomplete courses' do
        it 'recommends the first incomplete course' do
          user_stats = {
            'courses' => [
              {
                'course_id' => course_id_3,
                'title' => 'Incomplete Course',
                'completion_percentage' => 45.5
              },
              {
                'course_id' => 'course-4',
                'title' => 'Another Incomplete',
                'completion_percentage' => 80.0
              }
            ]
          }

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(user_stats)

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to eq(course_id_3)
          expect(recommendation[:title]).to eq('Incomplete Course')
          expect(recommendation[:reason]).to include('45.5% complete')
        end

        it 'handles course hash with missing title field' do
          user_stats = {
            'courses' => [
              {
                'course_id' => course_id_3,
                'completion_percentage' => 50
              }
            ]
          }

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(user_stats)

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to eq(course_id_3)
          expect(recommendation[:title]).to be_nil
        end

        it 'handles course hash with missing course_id field' do
          user_stats = {
            'courses' => [
              {
                'title' => 'Course Without ID',
                'completion_percentage' => 50
              }
            ]
          }

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(user_stats)

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to be_nil
        end

        it 'recommends course with 0% completion' do
          user_stats = {
            'courses' => [
              {
                'course_id' => course_id_3,
                'title' => 'New Course',
                'completion_percentage' => 0
              }
            ]
          }

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(user_stats)

          recommendation = service.recommend_next_course

          expect(recommendation[:course_id]).to eq(course_id_3)
          expect(recommendation[:reason]).to include('0% complete')
        end

        it 'recommends course with 99% completion (not 100%)' do
          user_stats = {
            'courses' => [
              {
                'course_id' => course_id_3,
                'title' => 'Almost Complete',
                'completion_percentage' => 99.9
              }
            ]
          }

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(user_stats)

          recommendation = service.recommend_next_course

          expect(recommendation[:course_id]).to eq(course_id_3)
          expect(recommendation[:reason]).to include('99.9% complete')
        end

        it 'skips courses with 100% completion' do
          user_stats = {
            'courses' => [
              {
                'course_id' => course_id_1,
                'title' => 'Completed Course',
                'completion_percentage' => 100
              },
              {
                'course_id' => course_id_3,
                'title' => 'Incomplete Course',
                'completion_percentage' => 50
              }
            ]
          }

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(user_stats)

          recommendation = service.recommend_next_course

          expect(recommendation[:course_id]).to eq(course_id_3)
          expect(recommendation[:reason]).to include('50% complete')
        end

        it 'handles courses without completion_percentage field' do
          user_stats = {
            'courses' => [
              {
                'course_id' => course_id_3,
                'title' => 'Course Without Percentage'
              }
            ]
          }

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(user_stats)

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to be_present
        end

        it 'handles courses array with nil values' do
          user_stats = {
            'courses' => [
              nil,
              {
                'course_id' => course_id_3,
                'title' => 'Valid Course',
                'completion_percentage' => 50
              }
            ]
          }

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(user_stats)

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to be_present
        end

        it 'handles courses with string completion_percentage' do
          user_stats = {
            'courses' => [
              {
                'course_id' => course_id_3,
                'title' => 'Course With String Percentage',
                'completion_percentage' => '50'
              }
            ]
          }

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(user_stats)

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to be_present
        end
      end

      context 'when LMS service returns user stats with only completed courses' do
        it 'falls back to history-based recommendation' do
          user_stats = {
            'courses' => [
              {
                'course_id' => course_id_1,
                'title' => 'Completed Course',
                'completion_percentage' => 100
              },
              {
                'course_id' => course_id_2,
                'title' => 'Another Completed',
                'completion_percentage' => 100
              }
            ]
          }

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(user_stats)

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to include(course_id_2)
          expect(recommendation[:reason]).to include('Based on your completion')
        end
      end

      context 'when LMS service returns user stats with empty courses array' do
        it 'falls back to history-based recommendation' do
          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return({ 'courses' => [] })

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to include(course_id_2)
          expect(recommendation[:reason]).to include('Based on your completion')
        end

        it 'handles user_stats without courses key' do
          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return({ 'user_id' => user_id })

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to include(course_id_2)
        end

        it 'handles user_stats with courses key set to nil' do
          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return({ 'courses' => nil })

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to include(course_id_2)
        end

        it 'handles user_stats with courses as non-array' do
          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return({ 'courses' => 'not-an-array' })

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to include(course_id_2)
        end
      end

      context 'when LMS service returns nil user stats' do
        it 'falls back to history-based recommendation' do
          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(nil)

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to include(course_id_2)
        end
      end

      context 'when LMS service raises an error' do
        it 'falls back to history-based recommendation' do
          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_raise(StandardError.new('Connection failed'))
          allow(Rails.logger).to receive(:error)

          recommendation = service.recommend_next_course

          expect(recommendation).to be_present
          expect(recommendation[:course_id]).to include(course_id_2)
          expect(Rails.logger).to have_received(:error).with(match(/Error fetching user stats from LMS/))
        end
      end

      context 'history-based fallback recommendations' do
        it 'recommends based on most recent course completion' do
          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(nil)

          recommendation = service.recommend_next_course

          expect(recommendation[:course_id]).to eq("related-to-#{course_id_2}")
          expect(recommendation[:title]).to eq('Advanced Course')
          expect(recommendation[:reason]).to include(course_id_2)
        end

        it 'handles multiple courses completed by same user' do
          Domain::ReadModels::LearnerHistory.create!(
            user_id: user_id,
            lesson_id: 'lesson-3',
            course_id: course_id_3,
            completed_at: 2.hours.ago,
            created_at: 2.hours.ago
          )

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(nil)

          recommendation = service.recommend_next_course

          expect(recommendation[:course_id]).to eq("related-to-#{course_id_3}")
        end

        it 'handles user with no recent course gracefully' do
          Domain::ReadModels::LearnerHistory.delete_all

          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(nil)

          allow(LmsClient).to receive(:get_courses).and_return([])

          recommendation = service.recommend_next_course

          expect(recommendation[:course_id]).to eq('beginner-course-001')
        end

        it 'returns popular course when recent_course is nil' do
          Domain::ReadModels::LearnerHistory.create!(
            user_id: user_id,
            lesson_id: 'lesson-1',
            course_id: course_id_1,
            completed_at: Time.current,
            created_at: Time.current
          )
          
          learner_history_relation = double('learner_history_relation')
          allow(Domain::ReadModels::LearnerHistory).to receive(:for_user).with(user_id).and_return(learner_history_relation)
          allow(learner_history_relation).to receive(:empty?).and_return(false)
          allow(learner_history_relation).to receive(:recent).and_return([])
          allow(learner_history_relation).to receive(:pluck).and_return([])
          allow(LmsClient).to receive(:get_user_stats).with(user_id).and_return(nil)

          recommendation = service.recommend_next_course

          expect(recommendation[:course_id]).to eq('popular-course-001')
          expect(recommendation[:title]).to eq('Popular Course')
          expect(recommendation[:reason]).to eq('Recommended based on popular courses')
        end
      end
    end

    context 'edge cases' do
      it 'handles empty user_id gracefully' do
        service = RecommendationService.new('')
        allow(LmsClient).to receive(:get_courses).and_return([])

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
      end

      it 'handles nil user_id gracefully' do
        service = RecommendationService.new(nil)
        allow(LmsClient).to receive(:get_courses).and_return([])

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
      end

      it 'handles very long user_id' do
        long_user_id = 'a' * 1000
        service = RecommendationService.new(long_user_id)
        allow(LmsClient).to receive(:get_courses).and_return([])

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
      end

      it 'handles special characters in user_id' do
        special_user_id = "user-123!@#$%^&*()"
        service = RecommendationService.new(special_user_id)
        allow(LmsClient).to receive(:get_courses).and_return([])

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
      end

      it 'executes pluck and uniq on learner_history' do
        Domain::ReadModels::LearnerHistory.create!(
          user_id: 'test-user',
          lesson_id: 'lesson-1',
          course_id: 'course-1',
          completed_at: Time.current,
          created_at: Time.current
        )
        Domain::ReadModels::LearnerHistory.create!(
          user_id: 'test-user',
          lesson_id: 'lesson-2',
          course_id: 'course-1',
          completed_at: Time.current,
          created_at: Time.current
        )

        service = RecommendationService.new('test-user')
        allow(LmsClient).to receive(:get_user_stats).and_return(nil)

        recommendation = service.recommend_next_course

        expect(recommendation).to be_present
      end
    end
  end
end
