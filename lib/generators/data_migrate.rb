require 'rails/generators/named_base'
module DataMigrate
  module Generators
    class DataMigrationGenerator < Rails::Generators::NamedBase #:nodoc:
      def self.source_root
         @_data_migrate_source_root ||= File.expand_path(File.join(File.dirname(__FILE__), generator_name, 'templates'))
      end
    end
  end
end
