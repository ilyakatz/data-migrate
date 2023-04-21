module DataMigrate
  class Railtie < ::Rails::Railtie
    generators = config.respond_to?(:app_generators) ? config.app_generators : config.generators

    rake_tasks do
      load File.join(File.dirname(__FILE__), '..', '..', 'tasks/databases.rake')
    end
  end
end
