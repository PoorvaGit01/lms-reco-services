# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Try to require sequent/spec if available
begin
  require 'sequent/spec'
rescue LoadError
  # sequent/spec not available in this version, create custom matcher
  RSpec::Matchers.define :have_applied do |expected_event_class|
    match do |aggregate|
      aggregate.uncommitted_events.any? { |e| e.is_a?(expected_event_class) }
    end
    
    failure_message do |aggregate|
      "expected aggregate to have applied #{expected_event_class}, but got: #{aggregate.uncommitted_events.map(&:class)}"
    end
  end
end

# Add additional requires below this line. Rails is not loaded until this point!

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  
  # Sequent configuration (if available)
  if defined?(Sequent::Spec::WorkflowHelpers)
    config.include Sequent::Spec::WorkflowHelpers
  end
end
