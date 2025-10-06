module DataMigrate
  include ActiveSupport::Configurable

  class << self
    def configure
      yield config
    end

    def config
      @config ||= Config.new
    end
  end

  class Config
    attr_accessor :data_migrations_table_name, :data_migrations_path, :data_template_path, :db_configuration, :spec_name, :test_generator_enabled, :test_generator_framework

    DEFAULT_DATA_TEMPLATE_PATH = "data_migration.rb"

    def initialize
      @data_migrations_table_name = "data_migrations"
      @data_migrations_path = "db/data/"
      @data_template_path = DEFAULT_DATA_TEMPLATE_PATH
      @db_configuration = nil
      @spec_name = nil
      @test_generator_enabled = false
      @test_generator_framework = DataMigrate::Helpers::InferTestFramework.new.call
    end

    def data_template_path=(value)
      @data_template_path = value.tap do |path|
        raise ArgumentError, "File not found: '#{path}'" unless path == DEFAULT_DATA_TEMPLATE_PATH || File.exist?(path)
      end
    end

    def test_generator_framework=(value)
      raise ArgumentError, "Invalid test generator framework: #{value}" unless [:rspec, :minitest].include?(value)

      @test_generator_framework = value
    end
  end
end
