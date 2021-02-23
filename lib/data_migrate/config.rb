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
    attr_accessor :data_migrations_path, :schema_migrations_paths, :db_configuration

    def initialize
      @data_migrations_path = "db/data/"
      @schema_migrations_paths = nil
      @db_configuration = nil
    end
  end
end
