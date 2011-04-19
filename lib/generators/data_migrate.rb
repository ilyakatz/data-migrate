require 'rails/generators/base'
require 'rails/generators/named_base'
module DataMigrate
  module Generators
    class InstallGenerator < Rails::Generators::Base #:nodoc:
      def self.source_root
         @_data_migrate_source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'data_migrate', generator_name, 'templates'))
      end
    end

    class DataMigrationGenerator < Rails::Generators::NamedBase #:nodoc:
      def self.source_root
         @_data_migrate_source_root ||= File.expand_path(File.join(File.dirname(__FILE__), generator_name, 'templates'))
      end
    end
  end
end
