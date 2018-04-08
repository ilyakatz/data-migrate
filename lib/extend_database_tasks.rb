module ActiveRecord
  module Tasks
    module DatabaseTasks
      def migrations_paths
        @migrations_paths ||= Rails.application.paths["db/migrate"].to_a + Rails.application.paths["db/data"].to_a
      end
    end
  end
end

ActiveRecord::Migrator.instance_eval do
  def migrations_paths
    @migrations_paths = Rails.application.paths["db/migrate"].to_a + Dir["#{Rails.root}/db/data"]
    # just to not break things if someone uses: migrations_path = some_string
    Array(@migrations_paths)
  end
end

ActiveRecord::Migrator.class_eval do
  def initialize(direction, migrations, target_version = nil)
    @direction         = direction
    @target_version    = target_version
    @migrated_versions = nil
    @migrations        = migrations

    validate(@migrations)

    ActiveRecord::SchemaMigration.create_table
    ActiveRecord::InternalMetadata.create_table

    DataMigrate::DataMigrator.assure_data_schema_table
  end
end
