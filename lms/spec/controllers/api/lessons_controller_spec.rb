require 'rails_helper'

RSpec.describe Api::LessonsController, type: :controller do
  before do
    Domain::ReadModels::Course.delete_all
    Domain::ReadModels::Lesson.delete_all
    Domain::ReadModels::LessonCompletion.delete_all
    Sequent::Core::EventRecord.delete_all
    Sequent::Core::CommandRecord.delete_all
    Sequent::Core::StreamRecord.delete_all
  end

  let(:course) { create_course }
  
  describe 'GET #index' do
    it 'returns all lessons' do
      lesson1 = create_lesson(course_id: course.aggregate_id, title: 'Lesson 1')
      lesson2 = create_lesson(course_id: course.aggregate_id, title: 'Lesson 2')
      
      get :index
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(2)
    end

    it 'filters lessons by course_id' do
      course2 = create_course(title: 'Course 2')
      lesson1 = create_lesson(course_id: course.aggregate_id, title: 'Lesson 1')
      lesson2 = create_lesson(course_id: course2.aggregate_id, title: 'Lesson 2')
      
      get :index, params: { course_id: course.aggregate_id }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['course_id']).to eq(course.aggregate_id)
    end
  end

  describe 'GET #show' do
    it 'returns lesson details' do
      lesson = create_lesson(course_id: course.aggregate_id, title: 'Test Lesson')
      
      get :show, params: { id: lesson.aggregate_id }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('Test Lesson')
      expect(json['course_id']).to eq(course.aggregate_id)
    end

    it 'returns 404 when lesson not found' do
      get :show, params: { id: 'non-existent-id' }
      
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Lesson not found')
    end
  end

  describe 'POST #create' do
    it 'creates a new lesson' do
      post :create, params: {
        course_id: course.aggregate_id,
        title: 'New Lesson',
        content: 'Lesson Content',
        order: 1
      }
      
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('New Lesson')
      expect(json['content']).to eq('Lesson Content')
    end

    it 'uses default order of 0 when order is not provided' do
      post :create, params: {
        course_id: course.aggregate_id,
        title: 'New Lesson',
        content: 'Lesson Content'
      }
      
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['order']).to eq(0)
    end

    it 'handles creation errors gracefully' do
      course_id = course.aggregate_id
      
      allow(Sequent.command_service).to receive(:execute_commands).and_raise(StandardError, 'Creation failed')
      
      post :create, params: {
        course_id: course_id,
        title: 'New Lesson',
        content: 'Lesson Content'
      }
      
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Creation failed')
    end
  end

  describe 'PUT #update' do
    it 'updates an existing lesson' do
      lesson = create_lesson(course_id: course.aggregate_id, title: 'Original Title')
      
      put :update, params: {
        id: lesson.aggregate_id,
        title: 'Updated Title',
        content: 'Updated Content',
        order: 2
      }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('Updated Title')
      expect(json['content']).to eq('Updated Content')
      expect(json['order']).to eq(2)
    end

    it 'returns error when lesson not found' do
      put :update, params: {
        id: 'non-existent-id',
        title: 'Updated Title'
      }
      
      expect(response).to have_http_status(:not_found)
    end

    it 'handles update errors gracefully' do
      lesson = create_lesson(course_id: course.aggregate_id)
      allow(Sequent.command_service).to receive(:execute_commands).and_raise(StandardError, 'Update failed')
      
      put :update, params: {
        id: lesson.aggregate_id,
        title: 'Updated Title'
      }
      
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Update failed')
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes an existing lesson' do
      lesson = create_lesson(course_id: course.aggregate_id, title: 'Lesson to Delete')
      
      delete :destroy, params: { id: lesson.aggregate_id }
      
      expect(response).to have_http_status(:no_content)
      expect(Domain::ReadModels::Lesson.find_by(aggregate_id: lesson.aggregate_id)).to be_nil
    end

    it 'returns error when lesson not found' do
      delete :destroy, params: { id: 'non-existent-id' }
      
      expect(response).to have_http_status(:not_found)
    end

    it 'handles delete errors gracefully' do
      lesson = create_lesson(course_id: course.aggregate_id)
      allow(Sequent.command_service).to receive(:execute_commands).and_raise(StandardError, 'Delete failed')
      
      delete :destroy, params: { id: lesson.aggregate_id }
      
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Delete failed')
    end
  end

  describe 'POST #complete' do
    it 'marks lesson as completed' do
      lesson = create_lesson(course_id: course.aggregate_id)
      
      post :complete, params: {
        id: lesson.aggregate_id,
        user_id: 'user-123'
      }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Lesson completed successfully')
    end

    it 'accepts user_id from header X-User-Id' do
      lesson = create_lesson(course_id: course.aggregate_id)
      
      request.headers['X-User-Id'] = 'user-from-header'
      post :complete, params: { id: lesson.aggregate_id }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Lesson completed successfully')
    end

    it 'returns error when user_id is missing' do
      lesson = create_lesson(course_id: course.aggregate_id)
      
      post :complete, params: { id: lesson.aggregate_id }
      
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('User ID is required')
    end

    it 'returns 404 when lesson not found' do
      post :complete, params: {
        id: 'non-existent-id',
        user_id: 'user-123'
      }
      
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Lesson not found')
    end

    it 'handles completion errors gracefully' do
      lesson = create_lesson(course_id: course.aggregate_id)
      allow(Sequent.command_service).to receive(:execute_commands).and_raise(StandardError, 'Completion failed')
      
      post :complete, params: {
        id: lesson.aggregate_id,
        user_id: 'user-123'
      }
      
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Completion failed')
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
end

