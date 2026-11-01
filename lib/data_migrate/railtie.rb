module DataMigrate
  class Railtie < ::Rails::Railtie
    generators = config.respond_to?(:app_generators) ? config.app_generators : config.generators

    rake_tasks do
      load File.join(File.dirname(__FILE__), '..', '..', 'tasks/databases.rake')
    end

    # Always added because config/initializers run after this initializer;
    # CheckPending.new returns the next app when the option is disabled.
    initializer "data_migrate.pending_migration_error" do |app|
      app.config.middleware.use DataMigrate::CheckPending, file_watcher: app.config.file_watcher
    end
  end
end
