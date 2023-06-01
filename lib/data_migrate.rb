# frozen_string_literal: true

require "active_record"

require File.join(File.dirname(__FILE__), "data_migrate", "data_schema")
require File.join(File.dirname(__FILE__), "data_migrate", "database_tasks")
require File.join(File.dirname(__FILE__), "data_migrate", "schema_dumper")
require File.join(File.dirname(__FILE__), "data_migrate", "status_service_five")
require File.join(File.dirname(__FILE__), "data_migrate", "migration_context")
require File.join(File.dirname(__FILE__), "data_migrate", "railtie")
require File.join(File.dirname(__FILE__), "data_migrate", "tasks/data_migrate_tasks")
require File.join(File.dirname(__FILE__), "data_migrate", "config")

if Gem::Version.new(Rails.version) >= Gem::Version.new("7.1.0.alpha")
  require File.join(File.dirname(__FILE__), "data_migrate", "data_migrator_seven_one")
  require File.join(File.dirname(__FILE__), "data_migrate", "schema_migration_seven_one")
  require File.join(File.dirname(__FILE__), "data_migrate", "data_schema_migration_seven_one")
else
  require File.join(File.dirname(__FILE__), "data_migrate", "data_migrator")
  require File.join(File.dirname(__FILE__), "data_migrate", "schema_migration_six")
  require File.join(File.dirname(__FILE__), "data_migrate", "data_schema_migration")
end

module DataMigrate
  def self.root
    File.dirname(__FILE__)
  end
end
