require 'rails/generators'
require 'rails/generators/migration'

module DataMigrate
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    source_root File.expand_path('../templates', __FILE__)

    def create_migration_file
      migration_template "install_migration.rb", "db/migrate/create_data_migrations.rb"
    end

    protected
    def self.next_migration_number(dirname)
      if ActiveRecord::Base.timestamped_migrations
        Time.new.utc.strftime("%Y%m%d%H%M%S")
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end
  end
end
