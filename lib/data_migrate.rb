# frozen_string_literal: true

if Rails::VERSION::MAJOR == 6
  require File.join(File.dirname(__FILE__), "data_migrate", "data_migrator_six")
elsif Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR == 2
  require File.join(File.dirname(__FILE__), "data_migrate", "data_migrator_five")
else
  require File.join(File.dirname(__FILE__), "data_migrate", "data_migrator")
end
require File.join(File.dirname(__FILE__), "data_migrate",
                  "data_schema_migration")
require File.join(File.dirname(__FILE__), "data_migrate", "data_schema")
require File.join(File.dirname(__FILE__), "data_migrate", "database_tasks")
require File.join(File.dirname(__FILE__), "data_migrate", "schema_dumper")
if Rails::VERSION::MAJOR == 6
  require File.join(File.dirname(__FILE__), "data_migrate", "status_service_five")
  require File.join(File.dirname(__FILE__), "data_migrate", "schema_migration_six")
elsif Rails::VERSION::MAJOR == 5 &&  Rails::VERSION::MINOR == 2
  require File.join(File.dirname(__FILE__), "data_migrate", "status_service_five")
  require File.join(File.dirname(__FILE__), "data_migrate", "schema_migration_five")
else
  require File.join(File.dirname(__FILE__), "data_migrate", "status_service")
  require File.join(File.dirname(__FILE__), "data_migrate", "schema_migration")
end

if Rails::VERSION::MAJOR == 6
  require File.join(File.dirname(__FILE__), "data_migrate", "migration_context")
  # require File.join(File.dirname(__FILE__), "data_migrate", "migration_five")
elsif Rails::VERSION::MAJOR == 5
  if Rails::VERSION::MINOR == 2
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
require File.join(File.dirname(__FILE__), "data_migrate", "config")

module DataMigrate
end
