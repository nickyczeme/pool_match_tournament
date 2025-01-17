ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require 'sqlite3'

DB = SQLite3::Database.new('db/test.sqlite3')
DB.results_as_hash = true

Rails.application.config.active_record.migration_error = false
Rails.application.config.active_record.schema_format = :sql

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
