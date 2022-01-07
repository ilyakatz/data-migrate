module DataMigrate
  module StatusServiceSix
    private

    def database
      ActiveRecord::Base.connection_config[:database]
    end
  end
end

DataMigrate::StatusService.prepend DataMigrate::StatusServiceSix
