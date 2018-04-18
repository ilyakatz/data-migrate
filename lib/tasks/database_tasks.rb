module DataMigrate
  module Tasks
    module DataMigrateTasks
      include ActiveRecord::Tasks::DatabaseTasks
      def migrations_paths
        @migrations_paths ||= Rails.application.paths["data/migrate"].to_a
      end
    end
  end
end
