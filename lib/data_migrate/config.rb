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
    attr_accessor :data_migrations_path, :data_template_path, :db_configuration, :spec_name, :test_support_enabled, :test_framework

    DEFAULT_DATA_TEMPLATE_PATH = "data_migration.rb"

    def initialize
      @data_migrations_path = "db/data/"
      @data_template_path = DEFAULT_DATA_TEMPLATE_PATH
      @db_configuration = nil
      @spec_name = nil
      @test_support_enabled = false
      @test_framework = nil
    end

    def data_template_path=(value)
      @data_template_path = value.tap do |path|
        raise ArgumentError, "File not found: '#{path}'" unless path == DEFAULT_DATA_TEMPLATE_PATH || File.exist?(path)
      end
    end

    def test_framework=(value)
      raise ArgumentError, "Invalid test framework: #{value}" unless [:rspec, :minitest].include?(value)

      @test_framework = value
    end
  end
end
