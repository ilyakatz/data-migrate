require File.join(File.dirname(__FILE__), 'data_migrate', 'data_migrator')
require File.join(File.dirname(__FILE__), 'data_migrate', 'data_schema_migration')
if Rails::VERSION::MAJOR >= 5
  require File.join(File.dirname(__FILE__), 'data_migrate', 'migration_five')
else
  require File.join(File.dirname(__FILE__), 'data_migrate', 'migration')
end
require File.join(File.dirname(__FILE__), 'data_migrate', 'silversheet_migration')
require File.join(File.dirname(__FILE__), 'data_migrate', 'railtie')
