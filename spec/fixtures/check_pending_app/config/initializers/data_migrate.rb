# frozen_string_literal: true

INITIALIZERS << "app config/initializers"

DataMigrate.configure do |config|
  config.data_migrations_path = File.expand_path("../../../../db/data", __dir__)
  config.pending_migration_error = ENV["PENDING_MIGRATION_ERROR"]&.to_sym
end
