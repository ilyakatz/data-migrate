module DataMigrate
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.dirname(__FILE__), '..', '..', 'tasks/databases.rake')
    end
  end
end
