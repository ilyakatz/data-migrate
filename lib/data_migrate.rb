# frozen_string_literal: true

if Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR == 2
  require File.join(File.dirname(__FILE__), "data_migrate", "data_migrator_five")
else
  require File.join(File.dirname(__FILE__), "data_migrate", "data_migrator")
end
require File.join(File.dirname(__FILE__), "data_migrate",
                  "data_schema_migration")
require File.join(File.dirname(__FILE__), "data_migrate", "data_schema")
require File.join(File.dirname(__FILE__), "data_migrate", "database_tasks")
require File.join(File.dirname(__FILE__), "data_migrate", "schema_dumper")
if Rails::VERSION::MAJOR == 5 &&  Rails::VERSION::MINOR == 2
  require File.join(File.dirname(__FILE__), "data_migrate", "status_service_five")
  require File.join(File.dirname(__FILE__), "data_migrate", "schema_migration_five")
else
  require File.join(File.dirname(__FILE__), "data_migrate", "status_service")
  require File.join(File.dirname(__FILE__), "data_migrate", "schema_migration")
end
if Rails::VERSION::MAJOR == 5
  if  Rails::VERSION::MINOR == 2
    require File.join(File.dirname(__FILE__), "data_migrate", "migration_context")
  else
    require File.join(File.dirname(__FILE__), "data_migrate", "migration_five")
  end
else
  require File.join(File.dirname(__FILE__), "data_migrate", "migration")
end
require File.join(File.dirname(__FILE__), "data_migrate", "railtie")
require File.join(File.dirname(__FILE__), "data_migrate", "tasks/data_migrate_tasks")
require File.join(File.dirname(__FILE__), "data_migrate", "legacy_migrator")

module DataMigrate
  include ActiveSupport::Configurable

  class << self
    def configure
      yield config
    end

    def data_migrations_paths
      @data_migrations_paths ||= Rails.application.paths["data/migrate"]&.existent || [ File.join(Rails.root, "data/data") ]
    end

    def db_migrations_paths
      @db_migrations_paths ||= Rails.application.paths["db/migrate"].existent || [ File.join(Rails.root, "db/migrate") ]
    end
  end
end
