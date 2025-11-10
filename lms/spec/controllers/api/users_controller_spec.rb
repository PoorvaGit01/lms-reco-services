require 'rails_helper'

RSpec.describe Api::UsersController, type: :controller do
  before do
    Domain::ReadModels::Course.delete_all
    Domain::ReadModels::Lesson.delete_all
    Domain::ReadModels::LessonCompletion.delete_all
    Sequent::Core::EventRecord.delete_all
    Sequent::Core::CommandRecord.delete_all
    Sequent::Core::StreamRecord.delete_all
  end

  describe 'GET #stats' do
    let(:user_id) { 'user-123' }

    it 'returns user statistics with no completions' do
      get :stats, params: { id: user_id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['user_id']).to eq(user_id)
      expect(json['total_lessons_completed']).to eq(0)
      expect(json['total_courses_enrolled']).to eq(0)
      expect(json['courses']).to eq([])
    end

    it 'returns user statistics with completed lessons' do
      course = create_course(title: 'Test Course')
      lesson1 = create_lesson(course_id: course.aggregate_id, title: 'Lesson 1')
      lesson2 = create_lesson(course_id: course.aggregate_id, title: 'Lesson 2')

      complete_lesson(lesson1.aggregate_id, user_id)
      complete_lesson(lesson2.aggregate_id, user_id)

      get :stats, params: { id: user_id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['user_id']).to eq(user_id)
      expect(json['total_lessons_completed']).to eq(2)
      expect(json['total_courses_enrolled']).to eq(1)
      expect(json['courses'].length).to eq(1)
      expect(json['courses'].first['completion_percentage']).to eq(100.0)
    end

    it 'returns user statistics with partial course completion' do
      course = create_course(title: 'Test Course')
      lesson1 = create_lesson(course_id: course.aggregate_id, title: 'Lesson 1')
      lesson2 = create_lesson(course_id: course.aggregate_id, title: 'Lesson 2')

      complete_lesson(lesson1.aggregate_id, user_id)

      get :stats, params: { id: user_id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['total_lessons_completed']).to eq(1)
      expect(json['total_courses_enrolled']).to eq(1)
      expect(json['courses'].first['completion_percentage']).to eq(50.0)
    end

    it 'returns user statistics for multiple courses' do
      course1 = create_course(title: 'Course 1')
      course2 = create_course(title: 'Course 2')
      lesson1 = create_lesson(course_id: course1.aggregate_id, title: 'Lesson 1')
      lesson2 = create_lesson(course_id: course2.aggregate_id, title: 'Lesson 2')

      complete_lesson(lesson1.aggregate_id, user_id)
      complete_lesson(lesson2.aggregate_id, user_id)

      get :stats, params: { id: user_id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['total_lessons_completed']).to eq(2)
      expect(json['total_courses_enrolled']).to eq(2)
      expect(json['courses'].length).to eq(2)
    end

    it 'handles errors gracefully' do
      allow(Domain::ReadModels::LessonCompletion).to receive(:where).and_raise(StandardError, 'Database error')

      get :stats, params: { id: user_id }

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Database error')
    end
  end

  private

  def create_course(title: 'Test Course')
    command = Domain::Commands::CreateCourse.new(
      aggregate_id: Sequent.new_uuid,
      title: title,
      description: 'Description',
      instructor_id: 'instructor-123'
    )
    Sequent.command_service.execute_commands(command)
    Domain::ReadModels::Course.find(command.aggregate_id)
  end

  def create_lesson(course_id:, title: 'Test Lesson', content: 'Content', order: 1)
    command = Domain::Commands::CreateLesson.new(
      aggregate_id: Sequent.new_uuid,
      course_id: course_id,
      title: title,
      content: content,
      order: order
    )
    Sequent.command_service.execute_commands(command)
    Domain::ReadModels::Lesson.find(command.aggregate_id)
  end

  def complete_lesson(lesson_id, user_id)
    command = Domain::Commands::CompleteLesson.new(
      aggregate_id: lesson_id,
      user_id: user_id
    )
    Sequent.command_service.execute_commands(command)
  end
end

