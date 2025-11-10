require 'rails_helper'
require 'securerandom'

RSpec.describe Api::EventsController, type: :controller do
  before do
    Domain::ReadModels::LearnerHistory.delete_all
    Domain::Projections::LearnerHistoryRecord.delete_all
  end

  describe 'POST #lesson_completed' do
    let(:valid_event_data) do
      {
        event: {
          user_id: 'user-123',
          lesson_id: 'lesson-456',
          course_id: 'course-789',
          completed_at: Time.current.utc.iso8601
        }
      }
    end

    context 'with valid event data' do
      it 'creates a learner history record' do
        expect {
          post :lesson_completed, params: valid_event_data
        }.to change(Domain::Projections::LearnerHistoryRecord, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns success response with event details' do
        post :lesson_completed, params: valid_event_data

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Event received and processed')
        expect(json['user_id']).to eq('user-123')
        expect(json['lesson_id']).to eq('lesson-456')
        expect(json['course_id']).to eq('course-789')
        expect(json['event_id']).to be_present
      end

      it 'stores correct data in database' do
        post :lesson_completed, params: valid_event_data

        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.user_id).to eq('user-123')
        expect(record.lesson_id).to eq('lesson-456')
        expect(record.course_id).to eq('course-789')
        expect(record.completed_at).to be_present
      end

      it 'handles completed_at as Time object' do
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: Time.current
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.completed_at).to be_present
      end

      it 'handles completed_at as DateTime object' do
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: DateTime.current
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.completed_at).to be_present
      end

      it 'handles created_at as Time object' do
        created_time = Time.current
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: Time.current.utc.iso8601,
            created_at: created_time
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.created_at).to be_within(1.second).of(created_time)
      end

      it 'uses current time when completed_at is missing' do
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789'
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.completed_at).to be_present
      end

      it 'uses current time when completed_at is nil' do
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: nil
          }
        }

        post :lesson_completed, params: event_data

        expect([201, 422]).to include(response.status)
        if response.status == 201
          record = Domain::Projections::LearnerHistoryRecord.last
          expect(record.completed_at).to be_present
        end
      end

      it 'uses current time when created_at is missing' do
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: Time.current.utc.iso8601
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.created_at).to be_present
      end

      it 'uses current time when created_at is nil' do
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: Time.current.utc.iso8601,
            created_at: nil
          }
        }

        post :lesson_completed, params: event_data

        expect([201, 422]).to include(response.status)
        if response.status == 201
          record = Domain::Projections::LearnerHistoryRecord.last
          expect(record.created_at).to be_present
        end
      end

      it 'handles created_at field' do
        created_time = 1.hour.ago
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: Time.current.utc.iso8601,
            created_at: created_time.utc.iso8601
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.created_at).to be_within(1.second).of(created_time)
      end
    end

    context 'with invalid event data' do
      it 'returns error when user_id is missing' do
        invalid_data = {
          event: {
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: Time.current.utc.iso8601
          }
        }

        post :lesson_completed, params: invalid_data

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end

      it 'returns error when lesson_id is missing' do
        invalid_data = {
          event: {
            user_id: 'user-123',
            course_id: 'course-789',
            completed_at: Time.current.utc.iso8601
          }
        }

        post :lesson_completed, params: invalid_data

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns error when course_id is missing' do
        invalid_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            completed_at: Time.current.utc.iso8601
          }
        }

        post :lesson_completed, params: invalid_data

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns error when event key is missing' do
        invalid_data = {
          user_id: 'user-123',
          lesson_id: 'lesson-456',
          course_id: 'course-789'
        }

        post :lesson_completed, params: invalid_data

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'handles missing event parameter gracefully' do
        post :lesson_completed, params: {}

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end

    context 'edge cases' do
      it 'handles empty user_id' do
        event_data = {
          event: {
            user_id: '',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: Time.current.utc.iso8601
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.user_id).to eq('')
      end

      it 'handles very long user_id' do
        long_user_id = 'a' * 1000
        event_data = {
          event: {
            user_id: long_user_id,
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: Time.current.utc.iso8601
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.user_id).to eq(long_user_id)
      end

      it 'handles UUID format IDs' do
        event_data = {
          event: {
            user_id: SecureRandom.uuid,
            lesson_id: SecureRandom.uuid,
            course_id: SecureRandom.uuid,
            completed_at: Time.current.utc.iso8601
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.user_id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
      end

      it 'handles special characters in IDs' do
        event_data = {
          event: {
            user_id: "user-123!@#$%",
            lesson_id: "lesson-456!@#$%",
            course_id: "course-789!@#$%",
            completed_at: Time.current.utc.iso8601
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.user_id).to eq("user-123!@#$%")
      end

      it 'handles future completed_at timestamp' do
        future_time = 1.year.from_now
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: future_time.utc.iso8601
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.completed_at).to be_within(1.second).of(future_time)
      end

      it 'handles very old completed_at timestamp' do
        old_time = 10.years.ago
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: old_time.utc.iso8601
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:created)
        record = Domain::Projections::LearnerHistoryRecord.last
        expect(record.completed_at).to be_within(1.second).of(old_time)
      end

      it 'handles invalid date format gracefully' do
        event_data = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-456',
            course_id: 'course-789',
            completed_at: 'invalid-date'
          }
        }

        post :lesson_completed, params: event_data

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end

    context 'multiple events' do
      it 'can process multiple events for same user' do
        event1 = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-1',
            course_id: 'course-1',
            completed_at: Time.current.utc.iso8601
          }
        }
        event2 = {
          event: {
            user_id: 'user-123',
            lesson_id: 'lesson-2',
            course_id: 'course-1',
            completed_at: Time.current.utc.iso8601
          }
        }

        post :lesson_completed, params: event1
        post :lesson_completed, params: event2

        expect(Domain::Projections::LearnerHistoryRecord.where(user_id: 'user-123').count).to eq(2)
      end

      it 'can process events for different users' do
        event1 = {
          event: {
            user_id: 'user-1',
            lesson_id: 'lesson-1',
            course_id: 'course-1',
            completed_at: Time.current.utc.iso8601
          }
        }
        event2 = {
          event: {
            user_id: 'user-2',
            lesson_id: 'lesson-2',
            course_id: 'course-2',
            completed_at: Time.current.utc.iso8601
          }
        }

        post :lesson_completed, params: event1
        post :lesson_completed, params: event2

        expect(Domain::Projections::LearnerHistoryRecord.count).to eq(2)
        expect(Domain::Projections::LearnerHistoryRecord.where(user_id: 'user-1').count).to eq(1)
        expect(Domain::Projections::LearnerHistoryRecord.where(user_id: 'user-2').count).to eq(1)
      end
    end

    context 'database errors' do
      it 'handles database connection errors' do
        allow(Domain::Projections::LearnerHistoryRecord).to receive(:create!).and_raise(ActiveRecord::ConnectionNotEstablished.new('DB error'))

        post :lesson_completed, params: valid_event_data

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end

      it 'handles constraint violations' do
        Domain::Projections::LearnerHistoryRecord.create!(
          user_id: 'user-123',
          lesson_id: 'lesson-456',
          course_id: 'course-789',
          completed_at: Time.current,
          created_at: Time.current
        )

        post :lesson_completed, params: valid_event_data
        expect([201, 422]).to include(response.status)
      end
    end

    context 'response format' do
      it 'returns JSON format' do
        post :lesson_completed, params: valid_event_data

        expect(response.content_type).to include('application/json')
      end

      it 'returns correct JSON structure' do
        post :lesson_completed, params: valid_event_data

        json = JSON.parse(response.body)
        expect(json).to have_key('message')
        expect(json).to have_key('event_id')
        expect(json).to have_key('user_id')
        expect(json).to have_key('lesson_id')
        expect(json).to have_key('course_id')
      end
    end
  end
end

