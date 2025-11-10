require 'rails_helper'

RSpec.describe Domain::ReadModels::Course, type: :model do
  before do
    Domain::ReadModels::Course.delete_all
    Domain::ReadModels::Lesson.delete_all
    Domain::ReadModels::LessonCompletion.delete_all
  end

  describe 'associations' do
    it 'has many lessons' do
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
      
      expect(course.lessons).to include(lesson)
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
      
      expect(course.completions).to include(completion)
    end
  end

  describe '#completion_percentage' do
    let(:course) do
      Domain::ReadModels::Course.create!(
        aggregate_id: Sequent.new_uuid,
        title: 'Test Course',
        description: 'Description',
        instructor_id: 'inst-1',
        created_at: Time.current
      )
    end

    let(:lesson1) do
      Domain::ReadModels::Lesson.create!(
        aggregate_id: Sequent.new_uuid,
        course_id: course.aggregate_id,
        title: 'Lesson 1',
        content: 'Content 1',
        order: 1,
        created_at: Time.current
      )
    end

    let(:lesson2) do
      Domain::ReadModels::Lesson.create!(
        aggregate_id: Sequent.new_uuid,
        course_id: course.aggregate_id,
        title: 'Lesson 2',
        content: 'Content 2',
        order: 2,
        created_at: Time.current
      )
    end

    it 'returns 0 when course has no lessons' do
      expect(course.completion_percentage('user-1')).to eq(0)
    end

    it 'returns 0 when user has completed no lessons' do
      lesson1
      lesson2
      
      expect(course.completion_percentage('user-1')).to eq(0)
    end

    it 'returns 50% when user completed 1 of 2 lessons' do
      lesson1
      lesson2
      
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-1',
        lesson_id: lesson1.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      expect(course.completion_percentage('user-1')).to eq(50.0)
    end

    it 'returns 100% when user completed all lessons' do
      lesson1
      lesson2
      
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-1',
        lesson_id: lesson1.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-1',
        lesson_id: lesson2.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      expect(course.completion_percentage('user-1')).to eq(100.0)
    end

    it 'counts unique lessons only (ignores duplicate completions)' do
      lesson1
      lesson2
      
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-1',
        lesson_id: lesson1.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-1',
        lesson_id: lesson1.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      expect(course.completion_percentage('user-1')).to eq(50.0)
    end

    it 'returns different percentages for different users' do
      lesson1
      lesson2
      
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-1',
        lesson_id: lesson1.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-2',
        lesson_id: lesson1.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-2',
        lesson_id: lesson2.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      expect(course.completion_percentage('user-1')).to eq(50.0)
      expect(course.completion_percentage('user-2')).to eq(100.0)
    end

    it 'rounds to 2 decimal places' do
      lesson1
      lesson2
      Domain::ReadModels::Lesson.create!(
        aggregate_id: Sequent.new_uuid,
        course_id: course.aggregate_id,
        title: 'Lesson 3',
        content: 'Content 3',
        order: 3,
        created_at: Time.current
      )
      
      Domain::ReadModels::LessonCompletion.create!(
        user_id: 'user-1',
        lesson_id: lesson1.aggregate_id,
        course_id: course.aggregate_id,
        completed_at: Time.current,
        created_at: Time.current
      )
      
      percentage = course.completion_percentage('user-1')
      expect(percentage).to eq(33.33)
      expect(percentage.to_s).to match(/^\d+\.\d{2}$/)
    end
  end
end

