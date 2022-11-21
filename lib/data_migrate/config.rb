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
    attr_accessor :data_migrations_path, :data_template_path, :db_configuration, :spec_name

    DEFAULT_DATA_TEMPLATE_PATH = "data_migration.rb"

    def initialize
      @data_migrations_path = "db/data/"
      @data_template_path = DEFAULT_DATA_TEMPLATE_PATH
      @db_configuration = nil
      @spec_name = nil
    end
  end
end
