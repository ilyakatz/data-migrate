require 'rspec'
require 'rails'
require 'sqlite3'
require 'data_migrate'
require 'pry'
require 'timecop'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:each) do |example|
    if example.metadata[:no_override]
    else
      if Rails::VERSION::MAJOR == 6
        DataMigrate.configure do |config|
          config.data_migrations_path = "spec/db/6.0"
        end
      elsif Rails::VERSION::MAJOR == 5
        if Rails::VERSION::MINOR == 2
          DataMigrate.configure do |config|
            config.data_migrations_path = "spec/db/data"
          end
        else
          DataMigrate.configure do |config|
            config.data_migrations_path = "spec/db/5.0"
          end
        end
      else
        DataMigrate.configure do |config|
          config.data_migrations_path = "spec/db/5.0"
        end
      end
    end
  end
end
