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
    attr_accessor :data_migrations_path, :db_configuration

    def initialize
      @data_migrations_path = "db/data/"
      @db_configuration = nil
    end
  end
end
