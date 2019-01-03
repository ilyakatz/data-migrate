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
    attr_accessor :data_migrations_path

    def initialize
      @data_migrations_path = File.join(Dir.pwd, "db/data/")
    end
  end
end
