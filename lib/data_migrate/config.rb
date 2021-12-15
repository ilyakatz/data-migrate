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
    attr_accessor :data_migrations_path, :migrations_path, :db_configuration, :spec_name

    def initialize
      @data_migrations_path = "db/data/"
      @migrations_path = "db/migrate/"
      @db_configuration = nil
      @spec_name = nil
    end
  end
end
