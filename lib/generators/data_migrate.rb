require 'rails/generators/named_base'

module DataMigrate
  module Generators
    class DataMigrationGenerator < Rails::Generators::NamedBase #:nodoc:
      class << self
        def source_root
          build_data_migrate_source_root
        end

        private

        def build_data_migrate_source_root
          if DataMigrate.config.data_template_path == DataMigrate::Config::DEFAULT_DATA_TEMPLATE_PATH
            File.expand_path(File.join(File.dirname(__FILE__), generator_name, 'templates'))
          else
            File.expand_path(File.dirname(DataMigrate.config.data_template_path))
          end
        end
      end
    end
  end
end
