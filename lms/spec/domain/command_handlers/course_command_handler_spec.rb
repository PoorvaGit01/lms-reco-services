require 'rails_helper'

RSpec.describe Domain::CommandHandlers::CourseCommandHandler, type: :command_handler do
  before do
    Sequent::Core::EventRecord.delete_all
    Sequent::Core::CommandRecord.delete_all
    Sequent::Core::StreamRecord.delete_all
    Domain::ReadModels::Course.delete_all
    Domain::ReadModels::Lesson.delete_all
  end

  describe 'handling CreateCourse command' do
    it 'creates a CourseCreated event' do
      command = Domain::Commands::CreateCourse.new(
        aggregate_id: Sequent.new_uuid,
        title: 'Test Course',
        description: 'Test Description',
        instructor_id: 'instructor-123'
      )

      Sequent.command_service.execute_commands(command)

      events = Sequent::Core::EventRecord.where(aggregate_id: command.aggregate_id)
      expect(events.count).to eq(1)
      expect(events.first.event_type).to eq('Domain::Events::CourseCreated')
    end

    it 'creates course aggregate' do
      command = Domain::Commands::CreateCourse.new(
        aggregate_id: Sequent.new_uuid,
        title: 'Test Course',
        description: 'Test Description',
        instructor_id: 'instructor-123'
      )

      Sequent.command_service.execute_commands(command)

      course = Domain::ReadModels::Course.find_by(aggregate_id: command.aggregate_id)
      expect(course).to be_present
      expect(course.title).to eq('Test Course')
      expect(course.description).to eq('Test Description')
      expect(course.instructor_id).to eq('instructor-123')
    end
  end

  describe 'handling UpdateCourse command' do
    let(:course_id) { Sequent.new_uuid }

    before do
      create_command = Domain::Commands::CreateCourse.new(
        aggregate_id: course_id,
        title: 'Original Title',
        description: 'Original Description',
        instructor_id: 'instructor-123'
      )
      Sequent.command_service.execute_commands(create_command)
    end

    it 'creates a CourseUpdated event' do
      update_command = Domain::Commands::UpdateCourse.new(
        aggregate_id: course_id,
        title: 'Updated Title',
        description: 'Updated Description'
      )

      Sequent.command_service.execute_commands(update_command)

      events = Sequent::Core::EventRecord.where(aggregate_id: course_id).order(:sequence_number)
      expect(events.count).to eq(2)
      expect(events.last.event_type).to eq('Domain::Events::CourseUpdated')
    end

    it 'updates course in read model' do
      update_command = Domain::Commands::UpdateCourse.new(
        aggregate_id: course_id,
        title: 'Updated Title',
        description: 'Updated Description'
      )

      Sequent.command_service.execute_commands(update_command)

      course = Domain::ReadModels::Course.find_by(aggregate_id: course_id)
      expect(course.title).to eq('Updated Title')
      expect(course.description).to eq('Updated Description')
    end
  end

  describe 'handling DeleteCourse command' do
    let(:course_id) { Sequent.new_uuid }

    before do
      create_command = Domain::Commands::CreateCourse.new(
        aggregate_id: course_id,
        title: 'Test Course',
        description: 'Test Description',
        instructor_id: 'instructor-123'
      )
      Sequent.command_service.execute_commands(create_command)
    end

    it 'creates a CourseDeleted event' do
      delete_command = Domain::Commands::DeleteCourse.new(aggregate_id: course_id)

      Sequent.command_service.execute_commands(delete_command)

      events = Sequent::Core::EventRecord.where(aggregate_id: course_id).order(:sequence_number)
      expect(events.count).to eq(2)
      expect(events.last.event_type).to eq('Domain::Events::CourseDeleted')
    end

    it 'deletes course from read model' do
      delete_command = Domain::Commands::DeleteCourse.new(aggregate_id: course_id)

      Sequent.command_service.execute_commands(delete_command)

      course = Domain::ReadModels::Course.find_by(aggregate_id: course_id)
      expect(course).to be_nil
    end
  end

  describe 'handling CreateLesson command' do
    let(:course_id) { Sequent.new_uuid }

    before do
      create_command = Domain::Commands::CreateCourse.new(
        aggregate_id: course_id,
        title: 'Test Course',
        description: 'Test Description',
        instructor_id: 'instructor-123'
      )
      Sequent.command_service.execute_commands(create_command)
    end

    it 'creates a LessonCreated event' do
      lesson_command = Domain::Commands::CreateLesson.new(
        aggregate_id: Sequent.new_uuid,
        course_id: course_id,
        title: 'Test Lesson',
        content: 'Test Content',
        order: 1
      )

      Sequent.command_service.execute_commands(lesson_command)

      events = Sequent::Core::EventRecord.where(aggregate_id: lesson_command.aggregate_id)
      expect(events.count).to eq(1)
      expect(events.first.event_type).to eq('Domain::Events::LessonCreated')
    end

    it 'creates lesson in read model' do
      lesson_id = Sequent.new_uuid
      lesson_command = Domain::Commands::CreateLesson.new(
        aggregate_id: lesson_id,
        course_id: course_id,
        title: 'Test Lesson',
        content: 'Test Content',
        order: 1
      )

      Sequent.command_service.execute_commands(lesson_command)

      lesson = Domain::ReadModels::Lesson.find_by(aggregate_id: lesson_id)
      expect(lesson).to be_present
      expect(lesson.title).to eq('Test Lesson')
      expect(lesson.content).to eq('Test Content')
      expect(lesson.order).to eq(1)
    end
  end

  describe 'handling CompleteLesson command' do
    let(:course_id) { Sequent.new_uuid }
    let(:lesson_id) { Sequent.new_uuid }

    before do
      create_course = Domain::Commands::CreateCourse.new(
        aggregate_id: course_id,
        title: 'Test Course',
        description: 'Test Description',
        instructor_id: 'instructor-123'
      )
      Sequent.command_service.execute_commands(create_course)

      create_lesson = Domain::Commands::CreateLesson.new(
        aggregate_id: lesson_id,
        course_id: course_id,
        title: 'Test Lesson',
        content: 'Test Content',
        order: 1
      )
      Sequent.command_service.execute_commands(create_lesson)
    end

    it 'creates a LessonCompleted event' do
      complete_command = Domain::Commands::CompleteLesson.new(
        aggregate_id: lesson_id,
        user_id: 'user-123'
      )

      Sequent.command_service.execute_commands(complete_command)

      events = Sequent::Core::EventRecord.where(aggregate_id: lesson_id).order(:sequence_number)
      expect(events.count).to eq(2)
      expect(events.last.event_type).to eq('Domain::Events::LessonCompleted')
    end

    it 'creates lesson completion in read model' do
      complete_command = Domain::Commands::CompleteLesson.new(
        aggregate_id: lesson_id,
        user_id: 'user-123'
      )

      Sequent.command_service.execute_commands(complete_command)

      completion = Domain::ReadModels::LessonCompletion.find_by(
        lesson_id: lesson_id,
        user_id: 'user-123'
      )
      expect(completion).to be_present
      expect(completion.course_id).to eq(course_id)
    end
  end
end

