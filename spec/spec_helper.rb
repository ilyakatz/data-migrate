require 'rspec'
require 'rails'
require 'data_migrate'
require 'pry'
require 'timecop'

if Rails::VERSION::MAJOR == 5 &&  Rails::VERSION::MINOR == 2
  DataMigrate::DataMigrator.migrations_paths = ["spec/db/data"]
end
