# frozen_string_literal: true

module Domain
  module CommandHandlers
    class CourseCommandHandler < Sequent::CommandHandler
      on Domain::Commands::CreateCourse do |command|
        repository.add_aggregate(
          Domain::Aggregates::Course.new(command)
        )
      end

      on Domain::Commands::UpdateCourse do |command|
        do_with_aggregate(command, Domain::Aggregates::Course) do |course|
          course.update(command)
        end
      end

      on Domain::Commands::DeleteCourse do |command|
        do_with_aggregate(command, Domain::Aggregates::Course, &:delete)
      end

      on Domain::Commands::CreateLesson do |command|
        repository.add_aggregate(
          Domain::Aggregates::Lesson.new(command)
        )
      end

      on Domain::Commands::UpdateLesson do |command|
        do_with_aggregate(command, Domain::Aggregates::Lesson) do |lesson|
          lesson.update(command)
        end
      end

      on Domain::Commands::DeleteLesson do |command|
        do_with_aggregate(command, Domain::Aggregates::Lesson, &:delete)
      end

      on Domain::Commands::CompleteLesson do |command|
        do_with_aggregate(command, Domain::Aggregates::Lesson) do |lesson|
          lesson.complete(command.user_id)
        end
      end
    end
  end
end
