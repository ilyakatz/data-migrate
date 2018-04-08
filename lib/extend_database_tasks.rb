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
