require 'rails_helper'

RSpec.describe Domain::Aggregates::Course, type: :aggregate do
  describe '#initialize' do
    let(:command) do
      Domain::Commands::CreateCourse.new(
        aggregate_id: Sequent.new_uuid,
        title: 'Test Course',
        description: 'Test Description',
        instructor_id: 'instructor-123'
      )
    end

    it 'creates a course with correct attributes' do
      course = Domain::Aggregates::Course.new(command)
      
      expect(course).to have_applied(Domain::Events::CourseCreated)
      expect(course.uncommitted_events.first.title).to eq('Test Course')
      expect(course.uncommitted_events.first.description).to eq('Test Description')
      expect(course.uncommitted_events.first.instructor_id).to eq('instructor-123')
    end
  end

  describe '#update' do
    let(:course_id) { Sequent.new_uuid }
    let(:course) do
      course = Domain::Aggregates::Course.new(
        Domain::Commands::CreateCourse.new(
          aggregate_id: course_id,
          title: 'Original Title',
          description: 'Original Description',
          instructor_id: 'instructor-123'
        )
      )
      # Clear uncommitted events to simulate committed state
      course.uncommitted_events.clear
      course
    end

    it 'updates course attributes' do
      update_command = Domain::Commands::UpdateCourse.new(
        aggregate_id: course_id,
        title: 'Updated Title',
        description: 'Updated Description'
      )
      
      course.update(update_command)
      
      expect(course).to have_applied(Domain::Events::CourseUpdated)
      expect(course.uncommitted_events.first.title).to eq('Updated Title')
    end
  end

  describe '#delete' do
    let(:course_id) { Sequent.new_uuid }
    let(:course) do
      course = Domain::Aggregates::Course.new(
        Domain::Commands::CreateCourse.new(
          aggregate_id: course_id,
          title: 'Test Course',
          description: 'Test Description',
          instructor_id: 'instructor-123'
        )
      )
      # Clear uncommitted events to simulate committed state
      course.uncommitted_events.clear
      course
    end

    it 'marks course as deleted' do
      delete_command = Domain::Commands::DeleteCourse.new(aggregate_id: course_id)
      course.delete
      
      expect(course).to have_applied(Domain::Events::CourseDeleted)
    end
  end
end

