require 'rspec'
require 'rails'
require 'sqlite3'
require 'data_migrate'
require 'pry'
require 'timecop'

if Rails::VERSION::MAJOR == 5 &&  Rails::VERSION::MINOR == 2
  DataMigrate::DataMigrator.migrations_paths = ["spec/db/data"]
end

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
