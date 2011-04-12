# require 'rails/generators/migration'
# class InstallGenerator < Rails::Generators::Base
#   source_root File.expand_path('../templates', __FILE__)
#   include Rails::Generators::Migration

#   def data_migrations_table_migration
#     generate("migration", "add_data_migrations_table version:text")
#     migration_template "install_migration.rb", "db/migrate/create_data_migrations.rb"
#   end
# end


#   protected
#   def self.next_migration_number(dirname)
#      Time.now.utc.strftime("%Y%m%d%H%M%S")
#    end
# end
require 'rails/generators'
require 'rails/generators/migration'
module DataMigration
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    def self.source_root
      @source_root ||= File.join(File.dirname(__FILE__), 'templates')
    end

    def self.next_migration_number(dirname)
      if ActiveRecord::Base.timestamped_migrations
        Time.new.utc.strftime("%Y%m%d%H%M%S")
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end

    def create_migration_file
      migration_template "install_migration.rb", "db/migrate/create_data_migrations.rb"
      #migration_template 'migration.rb', 'db/migrate/create_pages_table.rb'
    end
  end

end
