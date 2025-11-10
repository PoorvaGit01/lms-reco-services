# frozen_string_literal: true

module Domain
  module ReadModels
    class LearnerHistory < ApplicationRecord
      self.table_name = 'view_schema.learner_histories'

      scope :for_user, ->(user_id) { where(user_id: user_id) }
      scope :recent, -> { order(completed_at: :desc) }
    end
  end
end
