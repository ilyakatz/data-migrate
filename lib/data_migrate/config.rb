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
    attr_accessor :data_migrations_gen_path, :data_migrations_path, :db_configuration, :spec_name

    def initialize
      @data_migrations_path = "db/data/"
      @data_migrations_gen_path = "db/data/"
      @db_configuration = nil
      @spec_name = nil
    end
  end
end
