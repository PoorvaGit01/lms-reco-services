require 'rails_helper'
require 'securerandom'

RSpec.describe Api::UsersController, type: :controller do
  before do
    Domain::ReadModels::LearnerHistory.delete_all
    Domain::Projections::LearnerHistoryRecord.delete_all
  end

  describe 'GET #next_course' do
    let(:user_id) { 'user-123' }

    context 'for new learners' do
      it 'returns recommendation for new learner' do
        allow(RecommendationService).to receive_message_chain(:new, :recommend_next_course).and_return({
          course_id: 'beginner-course-001',
          title: 'Introduction to Learning',
          reason: 'Recommended for new learners'
        })

        get :next_course, params: { id: user_id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(user_id)
        expect(json['recommended_course']).to be_present
        expect(json['recommended_course']['course_id']).to eq('beginner-course-001')
        expect(json['recommended_course']['title']).to eq('Introduction to Learning')
        expect(json['recommended_course']['reason']).to eq('Recommended for new learners')
      end

      it 'returns 404 when no recommendation is available' do
        allow(RecommendationService).to receive_message_chain(:new, :recommend_next_course).and_return(nil)

        get :next_course, params: { id: user_id }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(user_id)
        expect(json['message']).to eq('No recommendations available at this time')
      end
    end

    context 'for existing learners' do
      before do
        Domain::ReadModels::LearnerHistory.create!(
          user_id: user_id,
          lesson_id: 'lesson-1',
          course_id: 'course-1',
          completed_at: Time.current,
          created_at: Time.current
        )
      end

      it 'returns recommendation based on learner history' do
        allow(RecommendationService).to receive_message_chain(:new, :recommend_next_course).and_return({
          course_id: 'course-2',
          title: 'Advanced Course',
          reason: 'Based on your completion of course course-1'
        })

        get :next_course, params: { id: user_id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(user_id)
        expect(json['recommended_course']['course_id']).to eq('course-2')
        expect(json['recommended_course']['reason']).to include('course-1')
      end

      it 'returns recommendation with incomplete course info' do
        allow(RecommendationService).to receive_message_chain(:new, :recommend_next_course).and_return({
          course_id: 'course-3',
          title: 'Incomplete Course',
          reason: 'Continue your learning - 45.5% complete'
        })

        get :next_course, params: { id: user_id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['recommended_course']['reason']).to include('45.5% complete')
      end
    end

    context 'error handling' do
      it 'handles service errors gracefully' do
        allow(RecommendationService).to receive(:new).and_raise(StandardError.new('Service error'))

        get :next_course, params: { id: user_id }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Service error')
      end

      it 'handles database errors gracefully' do
        allow(RecommendationService).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished.new('DB error'))

        get :next_course, params: { id: user_id }

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end

    context 'edge cases' do
      it 'handles empty user_id' do
        allow(RecommendationService).to receive_message_chain(:new, :recommend_next_course).and_return({
          course_id: 'course-1',
          title: 'Test Course',
          reason: 'Test reason'
        })

        get :next_course, params: { id: '' }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq('')
      end

      it 'handles very long user_id' do
        long_user_id = 'a' * 1000
        allow(RecommendationService).to receive_message_chain(:new, :recommend_next_course).and_return({
          course_id: 'course-1',
          title: 'Test Course',
          reason: 'Test reason'
        })

        get :next_course, params: { id: long_user_id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(long_user_id)
      end

      it 'handles special characters in user_id' do
        special_user_id = "user-123!@#$%^&*()"
        allow(RecommendationService).to receive_message_chain(:new, :recommend_next_course).and_return({
          course_id: 'course-1',
          title: 'Test Course',
          reason: 'Test reason'
        })

        get :next_course, params: { id: special_user_id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(special_user_id)
      end

      it 'handles UUID format user_id' do
        uuid_user_id = SecureRandom.uuid
        allow(RecommendationService).to receive_message_chain(:new, :recommend_next_course).and_return({
          course_id: 'course-1',
          title: 'Test Course',
          reason: 'Test reason'
        })

        get :next_course, params: { id: uuid_user_id }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq(uuid_user_id)
      end
    end

    context 'response format' do
      it 'returns JSON format' do
        allow(RecommendationService).to receive_message_chain(:new, :recommend_next_course).and_return({
          course_id: 'course-1',
          title: 'Test Course',
          reason: 'Test reason'
        })

        get :next_course, params: { id: user_id }

        expect(response.content_type).to include('application/json')
      end

      it 'returns correct JSON structure' do
        allow(RecommendationService).to receive_message_chain(:new, :recommend_next_course).and_return({
          course_id: 'course-1',
          title: 'Test Course',
          reason: 'Test reason'
        })

        get :next_course, params: { id: user_id }

        json = JSON.parse(response.body)
        expect(json).to have_key('user_id')
        expect(json).to have_key('recommended_course')
        expect(json['recommended_course']).to have_key('course_id')
        expect(json['recommended_course']).to have_key('title')
        expect(json['recommended_course']).to have_key('reason')
      end
    end
  end
end

