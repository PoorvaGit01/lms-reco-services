require 'rails_helper'

RSpec.describe Domain::ReadModels::Lesson, type: :model do
  before do
    Domain::ReadModels::Course.delete_all
    Domain::ReadModels::Lesson.delete_all
    Domain::ReadModels::LessonCompletion.delete_all
  end

  describe 'associations' do
    it 'belongs to course' do
      course = Domain::ReadModels::Course.create!(
        aggregate_id: Sequent.new_uuid,
        title: 'Test Course',
        description: 'Description',
        instructor_id: 'inst-1',
        created_at: Time.current
      )
      
      lesson = Domain::ReadModels::Lesson.create!(
        aggregate_id: Sequent.new_uuid,
        course_id: course.aggregate_id,
        title: 'Lesson 1',
        content: 'Content',
        order: 1,
        created_at: Time.current
      )
      
      expect(lesson.course).to eq(course)
    end

    it 'has many completions' do
      course = Domain::ReadModels::Course.create!(
        aggregate_id: Sequent.new_uuid,
        title: 'Test Course',
        description: 'Description',
        instructor_id: 'inst-1',
        created_at: Time.current
      )
      
      lesson = Domain::ReadModels::Lesson.create!(
        aggregate_id: Sequent.new_uuid,
        course_id: course.aggregate_id,
        title: 'Lesson 1',
        content: 'Content',
        order: 1,
        created_at: Time.current
      )
      
      completion = Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-1',
        lesson_id: lesson.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      expect(lesson.completions).to include(completion)
    end
  end

  describe '#completed_by?' do
    let(:course) do
      Domain::ReadModels::Course.create!(
        aggregate_id: Sequent.new_uuid,
        title: 'Test Course',
        description: 'Description',
        instructor_id: 'inst-1',
        created_at: Time.current
      )
    end

    let(:lesson) do
      Domain::ReadModels::Lesson.create!(
        aggregate_id: Sequent.new_uuid,
        course_id: course.aggregate_id,
        title: 'Lesson 1',
        content: 'Content',
        order: 1,
        created_at: Time.current
      )
    end

    it 'returns false when user has not completed the lesson' do
      expect(lesson.completed_by?('user-1')).to be false
    end

    it 'returns true when user has completed the lesson' do
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-1',
        lesson_id: lesson.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      expect(lesson.completed_by?('user-1')).to be true
    end

    it 'returns false for different user' do
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-1',
        lesson_id: lesson.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      expect(lesson.completed_by?('user-2')).to be false
    end

    it 'handles empty user_id' do
      expect(lesson.completed_by?('')).to be false
    end

    it 'handles nil user_id' do
      expect(lesson.completed_by?(nil)).to be false
    end
  end
end
