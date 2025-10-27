module DataMigrate
  class << self

    def configure
      yield config
    end

    def config
      @config ||= Config.new
    end
  end

  class Config
    attr_accessor :data_migrations_table_name, :data_migrations_path, :data_template_path, :db_configuration, :spec_name

    DEFAULT_DATA_TEMPLATE_PATH = "data_migration.rb"

    def initialize
      @data_migrations_table_name = "data_migrations"
      @data_migrations_path = "db/data/"
      @data_template_path = DEFAULT_DATA_TEMPLATE_PATH
      @db_configuration = nil
      @spec_name = nil
    end

    def data_template_path=(value)
      @data_template_path = value.tap do |path|
        raise ArgumentError, "File not found: '#{path}'" unless path == DEFAULT_DATA_TEMPLATE_PATH || File.exist?(path)
      end
    end
  end
end
