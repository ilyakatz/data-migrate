# frozen_string_literal: true

module DataMigrate
  class LegacyMigrator
    def initialize(migrations_paths = "db/data")
      @migrations_paths = migrations_paths || "db/data"
    end

    def migrate
      dates =
        DataMigrate::DataMigrator.migrations(@migrations_paths).collect(&:version)
      legacy = ActiveRecord::SchemaMigration.where(version: dates)
      legacy.each do |v|
        begin
          version = v.version
          puts "Creating #{version} in data schema"
          DataMigrate::DataSchemaMigration.create(version: version)
        rescue ActiveRecord::RecordNotUnique
          nil
        end
      end
    end
  end
end
