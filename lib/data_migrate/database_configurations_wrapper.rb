module DataMigrate
  # This wrapper is used to differentiate between
  # a data and schema db config when running migrations
  class DatabaseConfigurationWrapper
    attr_reader :db_config

    def initialize(db_config)
      @db_config = db_config
    end
  end
end
