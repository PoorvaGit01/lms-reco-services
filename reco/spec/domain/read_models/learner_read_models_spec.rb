require 'rails_helper'

RSpec.describe Domain::ReadModels::LearnerHistory, type: :model do
  before do
    Domain::ReadModels::LearnerHistory.delete_all
  end

  describe 'scopes' do
    let(:user_id) { 'user-123' }
    let(:other_user_id) { 'user-456' }

    before do
      Domain::ReadModels::LearnerHistory.create!(
        user_id: user_id,
        lesson_id: 'lesson-1',
        course_id: 'course-1',
        completed_at: 3.days.ago,
        created_at: 3.days.ago
      )
      
      Domain::ReadModels::LearnerHistory.create!(
        user_id: user_id,
        lesson_id: 'lesson-2',
        course_id: 'course-1',
        completed_at: 1.day.ago,
        created_at: 1.day.ago
      )
      
      Domain::ReadModels::LearnerHistory.create!(
        user_id: other_user_id,
        lesson_id: 'lesson-3',
        course_id: 'course-2',
        completed_at: 2.days.ago,
        created_at: 2.days.ago
      )
    end

    describe '.for_user' do
      it 'returns only records for specified user' do
        records = Domain::ReadModels::LearnerHistory.for_user(user_id)
        
        expect(records.count).to eq(2)
        expect(records.pluck(:user_id).uniq).to eq([user_id])
      end

      it 'returns empty array for user with no history' do
        records = Domain::ReadModels::LearnerHistory.for_user('non-existent-user')
        
        expect(records).to be_empty
      end
    end

    describe '.recent' do
      it 'orders records by completed_at descending' do
        records = Domain::ReadModels::LearnerHistory.recent
        
        expect(records.first.completed_at).to be > records.last.completed_at
      end

      it 'returns most recent record first' do
        records = Domain::ReadModels::LearnerHistory.for_user(user_id).recent
        
        expect(records.first.lesson_id).to eq('lesson-2')
        expect(records.last.lesson_id).to eq('lesson-1')
      end

      it 'works with for_user scope' do
        records = Domain::ReadModels::LearnerHistory.for_user(user_id).recent
        
        expect(records.count).to eq(2)
        expect(records.first.completed_at).to be > records.last.completed_at
      end
    end
  end

  describe 'edge cases' do
    it 'handles empty user_id' do
      Domain::ReadModels::LearnerHistory.create!(
        user_id: '',
        lesson_id: 'lesson-1',
        course_id: 'course-1',
        completed_at: Time.current,
        created_at: Time.current
      )
      
      records = Domain::ReadModels::LearnerHistory.for_user('')
      expect(records.count).to eq(1)
    end

    it 'handles same lesson completed multiple times' do
      Domain::ReadModels::LearnerHistory.create!(
        user_id: 'user-1',
        lesson_id: 'lesson-1',
        course_id: 'course-1',
        completed_at: 1.day.ago,
        created_at: 1.day.ago
      )
      
      Domain::ReadModels::LearnerHistory.create!(
        user_id: 'user-1',
        lesson_id: 'lesson-1',
        course_id: 'course-1',
        completed_at: Time.current,
        created_at: Time.current
      )
      
      records = Domain::ReadModels::LearnerHistory.for_user('user-1')
      expect(records.count).to eq(2)
    end
  end
end

