module DataMigrate
  class DataMigateConfigurator
    include ActiveSupport::Configurable
    config_accessor :legacy_support
  end
end
