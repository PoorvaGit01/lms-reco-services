require 'rails_helper'

RSpec.describe Domain::Aggregates::Lesson, type: :aggregate do
  describe '#initialize' do
    let(:command) do
      Domain::Commands::CreateLesson.new(
        aggregate_id: Sequent.new_uuid,
        course_id: Sequent.new_uuid,
        title: 'Test Lesson',
        content: 'Test Content',
        order: 1
      )
    end

    it 'creates a lesson with correct attributes' do
      lesson = Domain::Aggregates::Lesson.new(command)
      
      expect(lesson).to have_applied(Domain::Events::LessonCreated)
      expect(lesson.uncommitted_events.first.title).to eq('Test Lesson')
      expect(lesson.uncommitted_events.first.order).to eq(1)
    end
  end

  describe '#complete' do
    let(:lesson_id) { Sequent.new_uuid }
    let(:course_id) { Sequent.new_uuid }
    let(:lesson) do
      lesson = Domain::Aggregates::Lesson.new(
        Domain::Commands::CreateLesson.new(
          aggregate_id: lesson_id,
          course_id: course_id,
          title: 'Test Lesson',
          content: 'Test Content',
          order: 1
        )
      )
      lesson.uncommitted_events.clear
      lesson
    end

    it 'marks lesson as completed' do
      user_id = 'user-123'
      lesson.complete(user_id)
      
      expect(lesson).to have_applied(Domain::Events::LessonCompleted)
      event = lesson.uncommitted_events.first
      expect(event.user_id).to eq(user_id)
      expect(event.lesson_id).to eq(lesson_id)
      expect(event.course_id).to eq(course_id)
    end
  end
end

