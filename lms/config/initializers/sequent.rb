require 'sequent'

# Helper to safely require a file, catching double-load errors
def safe_require(file_path)
  require file_path
rescue ArgumentError => e
  # If attribute already defined, file is already loaded - skip it
  raise unless e.message.include?('already defined')
end

Rails.application.config.after_initialize do
  # Load view schema migration first
  require Rails.root.join('db/sequent/view_schema_v1.rb')
  
  # Load domain files manually, catching double-load errors
  domain_path = Rails.root.join('app/domain')
  
  # Load in dependency order
  Dir[domain_path.join('events/**/*.rb')].sort.each { |f| safe_require(f) }
  Dir[domain_path.join('commands/**/*.rb')].sort.each { |f| safe_require(f) }
  Dir[domain_path.join('aggregates/**/*.rb')].sort.each { |f| safe_require(f) }
  Dir[domain_path.join('read_models/**/*.rb')].sort.each { |f| safe_require(f) }
  Dir[domain_path.join('command_handlers/**/*.rb')].sort.each { |f| safe_require(f) }
  Dir[domain_path.join('projections/**/*.rb')].sort.each { |f| safe_require(f) }
  
  # Configure Sequent - use class instances instead of class constants
  Sequent.configure do |config|
    config.command_handlers = [
      Domain::CommandHandlers::CourseCommandHandler.new
    ]
    
    config.event_handlers = [
      Domain::Projections::CourseProjection.new
    ]
    
    config.database_config_directory = Rails.root.join('config')
  end
end


