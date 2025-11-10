require 'rails_helper'

RSpec.describe Api::CoursesController, type: :controller do
  before do
    Domain::ReadModels::Course.delete_all
    Domain::ReadModels::Lesson.delete_all
    Domain::ReadModels::LessonCompletion.delete_all
    Sequent::Core::EventRecord.delete_all
    Sequent::Core::CommandRecord.delete_all
    Sequent::Core::StreamRecord.delete_all
  end

  describe 'GET #index' do
    it 'returns all courses' do
      course1 = create_course(title: 'Course 1')
      course2 = create_course(title: 'Course 2')
      
      get :index
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end
  end

  describe 'POST #create' do
    it 'creates a new course' do
      post :create, params: {
        title: 'New Course',
        description: 'Course Description',
        instructor_id: 'instructor-123'
      }
      
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('New Course')
    end
  end

  describe 'GET #show' do
    it 'returns course details' do
      course = create_course(title: 'Test Course')
      
      get :show, params: { id: course.aggregate_id }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('Test Course')
    end

    it 'returns course with completion percentage when user_id is provided' do
      course = create_course(title: 'Test Course')
      lesson = create_lesson(course_id: course.aggregate_id)
      user_id = 'user-123'
      
      # Complete the lesson
      complete_command = Domain::Commands::CompleteLesson.new(
        aggregate_id: lesson.aggregate_id,
        user_id: user_id
      )
      Sequent.command_service.execute_commands(complete_command)
      
      get :show, params: { id: course.aggregate_id, user_id: user_id }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['completion_percentage']).to eq(100.0)
    end

    it 'returns 404 when course not found' do
      get :show, params: { id: 'non-existent-id' }
      
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Course not found')
    end
  end

  describe 'PUT #update' do
    it 'updates an existing course' do
      course = create_course(title: 'Original Title')
      
      put :update, params: {
        id: course.aggregate_id,
        title: 'Updated Title',
        description: 'Updated Description'
      }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('Updated Title')
      expect(json['description']).to eq('Updated Description')
    end

    it 'returns error when course not found' do
      put :update, params: {
        id: 'non-existent-id',
        title: 'Updated Title'
      }
      
      expect(response).to have_http_status(:not_found)
    end

    it 'handles update errors gracefully' do
      course = create_course(title: 'Test Course')
      
      allow(Sequent.command_service).to receive(:execute_commands).and_raise(StandardError, 'Update failed')
      
      put :update, params: {
        id: course.aggregate_id,
        title: 'Updated Title'
      }
      
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Update failed')
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes an existing course' do
      course = create_course(title: 'Course to Delete')
      
      delete :destroy, params: { id: course.aggregate_id }
      
      expect(response).to have_http_status(:no_content)
      expect(Domain::ReadModels::Course.find_by(aggregate_id: course.aggregate_id)).to be_nil
    end

    it 'returns error when course not found' do
      delete :destroy, params: { id: 'non-existent-id' }
      
      expect(response).to have_http_status(:not_found)
    end

    it 'handles delete errors gracefully' do
      course = create_course(title: 'Test Course')
      
      allow(Sequent.command_service).to receive(:execute_commands).and_raise(StandardError, 'Delete failed')
      
      delete :destroy, params: { id: course.aggregate_id }
      
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Delete failed')
    end
  end

  describe 'POST #create' do
    it 'handles creation errors gracefully' do
      allow(Sequent.command_service).to receive(:execute_commands).and_raise(StandardError, 'Creation failed')
      
      post :create, params: {
        title: 'New Course',
        description: 'Course Description',
        instructor_id: 'instructor-123'
      }
      
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Creation failed')
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

  def create_lesson(course_id:)
    command = Domain::Commands::CreateLesson.new(
      aggregate_id: Sequent.new_uuid,
      course_id: course_id,
      title: 'Test Lesson',
      content: 'Content',
      order: 1
    )
    Sequent.command_service.execute_commands(command)
    Domain::ReadModels::Lesson.find(command.aggregate_id)
  end
end

