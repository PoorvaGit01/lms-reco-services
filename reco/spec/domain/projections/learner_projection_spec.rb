require 'rails_helper'

RSpec.describe Domain::Projections::LearnerHistoryProjection do
  before do
    Domain::Projections::LearnerHistoryRecord.delete_all
    Sequent::Core::EventRecord.delete_all
  end

  describe 'projection configuration' do
    it 'is a Sequent projector' do
      expect(Domain::Projections::LearnerHistoryProjection.ancestors).to include(Sequent::Projector)
    end

    it 'handles LessonCompleted events' do
      expect(Domain::Projections::LearnerHistoryProjection).to be_a(Class)
    end
  end

  describe 'event handling' do
    it 'executes the projection handler on block when event is processed' do
      event = Domain::Events::LessonCompleted.new(
        aggregate_id: Sequent.new_uuid,
        sequence_number: 1,
        user_id: 'user-123',
        lesson_id: 'lesson-456',
        course_id: 'course-789',
        completed_at: Time.current,
        created_at: Time.current
      )

      expect {
        projection = Domain::Projections::LearnerHistoryProjection.new
        projection.handle_message(event)
      }.to change(Domain::Projections::LearnerHistoryRecord, :count).by(1)

      record = Domain::Projections::LearnerHistoryRecord.last
      expect(record.user_id).to eq('user-123')
      expect(record.lesson_id).to eq('lesson-456')
      expect(record.course_id).to eq('course-789')
    end

    it 'creates a LearnerHistoryRecord when LessonCompleted event is processed' do
      event = Domain::Events::LessonCompleted.new(
        aggregate_id: Sequent.new_uuid,
        sequence_number: 1,
        user_id: 'user-123',
        lesson_id: 'lesson-456',
        course_id: 'course-789',
        completed_at: Time.current,
        created_at: Time.current
      )

      expect {
        Domain::Projections::LearnerHistoryRecord.create!(
          user_id:      event.user_id,
          lesson_id:    event.lesson_id,
          course_id:    event.course_id,
          completed_at: event.completed_at,
          created_at:   event.created_at
        )
      }.to change(Domain::Projections::LearnerHistoryRecord, :count).by(1)

      record = Domain::Projections::LearnerHistoryRecord.last
      expect(record.user_id).to eq('user-123')
      expect(record.lesson_id).to eq('lesson-456')
      expect(record.course_id).to eq('course-789')
    end

    it 'handles multiple LessonCompleted events' do
      event1 = Domain::Events::LessonCompleted.new(
        aggregate_id: 'aggregate-1',
        sequence_number: 1,
        user_id: 'user-123',
        lesson_id: 'lesson-1',
        course_id: 'course-1',
        completed_at: Time.current,
        created_at: Time.current
      )
      event2 = Domain::Events::LessonCompleted.new(
        aggregate_id: 'aggregate-2',
        sequence_number: 1,
        user_id: 'user-123',
        lesson_id: 'lesson-2',
        course_id: 'course-1',
        completed_at: Time.current,
        created_at: Time.current
      )

      expect {
        Domain::Projections::LearnerHistoryRecord.create!(
          user_id: event1.user_id,
          lesson_id: event1.lesson_id,
          course_id: event1.course_id,
          completed_at: event1.completed_at,
          created_at: event1.created_at
        )
        Domain::Projections::LearnerHistoryRecord.create!(
          user_id: event2.user_id,
          lesson_id: event2.lesson_id,
          course_id: event2.course_id,
          completed_at: event2.completed_at,
          created_at: event2.created_at
        )
      }.to change(Domain::Projections::LearnerHistoryRecord, :count).by(2)
    end

    it 'handles events with different users' do
      event1 = Domain::Events::LessonCompleted.new(
        aggregate_id: 'aggregate-1',
        sequence_number: 1,
        user_id: 'user-1',
        lesson_id: 'lesson-1',
        course_id: 'course-1',
        completed_at: Time.current,
        created_at: Time.current
      )
      event2 = Domain::Events::LessonCompleted.new(
        aggregate_id: 'aggregate-2',
        sequence_number: 1,
        user_id: 'user-2',
        lesson_id: 'lesson-2',
        course_id: 'course-2',
        completed_at: Time.current,
        created_at: Time.current
      )

      Domain::Projections::LearnerHistoryRecord.create!(
        user_id: event1.user_id,
        lesson_id: event1.lesson_id,
        course_id: event1.course_id,
        completed_at: event1.completed_at,
        created_at: event1.created_at
      )
      Domain::Projections::LearnerHistoryRecord.create!(
        user_id: event2.user_id,
        lesson_id: event2.lesson_id,
        course_id: event2.course_id,
        completed_at: event2.completed_at,
        created_at: event2.created_at
      )

      expect(Domain::Projections::LearnerHistoryRecord.where(user_id: 'user-1').count).to eq(1)
      expect(Domain::Projections::LearnerHistoryRecord.where(user_id: 'user-2').count).to eq(1)
    end

    it 'handles event with all required attributes' do
      completed_time = Time.current
      created_time = Time.current
      event = Domain::Events::LessonCompleted.new(
        aggregate_id: 'aggregate-123',
        sequence_number: 1,
        user_id: 'user-123',
        lesson_id: 'lesson-456',
        course_id: 'course-789',
        completed_at: completed_time,
        created_at: created_time
      )

      Domain::Projections::LearnerHistoryRecord.create!(
        user_id: event.user_id,
        lesson_id: event.lesson_id,
        course_id: event.course_id,
        completed_at: event.completed_at,
        created_at: event.created_at
      )

      record = Domain::Projections::LearnerHistoryRecord.last
      expect(record.user_id).to eq('user-123')
      expect(record.lesson_id).to eq('lesson-456')
      expect(record.course_id).to eq('course-789')
      expect(record.completed_at).to be_within(1.second).of(completed_time)
      expect(record.created_at).to be_within(1.second).of(created_time)
    end
  end

  describe 'LearnerHistoryRecord' do
    it 'has correct table name' do
      expect(Domain::Projections::LearnerHistoryRecord.table_name).to eq('view_schema.learner_histories')
    end

    it 'can create records' do
      record = Domain::Projections::LearnerHistoryRecord.create!(
        user_id: 'user-123',
        lesson_id: 'lesson-456',
        course_id: 'course-789',
        completed_at: Time.current,
        created_at: Time.current
      )

      expect(record).to be_persisted
      expect(record.user_id).to eq('user-123')
    end

    it 'inherits from ApplicationRecord' do
      expect(Domain::Projections::LearnerHistoryRecord.ancestors).to include(ApplicationRecord)
    end
  end
end
