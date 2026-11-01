# frozen_string_literal: true

module DataMigrate
  class CheckPending
    def self.new(app, **options)
      return app unless DataMigrate.config.pending_migration_error == :page_load

      super
    end

    def initialize(app, file_watcher: ActiveSupport::FileUpdateChecker)
      @app = app
      @needs_check = true
      @mutex = Mutex.new
      @file_watcher = file_watcher
    end

    def call(env)
      @mutex.synchronize do
        @watcher ||= build_watcher do
          @needs_check = true
          check_pending!
          @needs_check = false
        end

        if @needs_check
          @watcher.execute
        else
          @watcher.execute_if_updated
        end
      end

      @app.call(env)
    end

    private

    def build_watcher(&block)
      paths = Array.wrap(DataMigrate.config.data_migrations_path).map(&:to_s)
      @file_watcher.new([], paths.index_with(["rb"]), &block)
    end

    def check_pending!
      pending_migrations = DataMigrate::DatabaseTasks.pending_data_migrations
      raise DataMigrate::PendingMigrationError.new(pending_migrations: pending_migrations) if pending_migrations.any?
    end
  end
end
