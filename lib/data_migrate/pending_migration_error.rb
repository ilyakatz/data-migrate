# frozen_string_literal: true

module DataMigrate
  class PendingMigrationError < ActiveRecord::MigrationError
    include ActiveSupport::ActionableError

    action "Run pending data migrations" do
      DataMigrate::Tasks::DataMigrateTasks.migrate
      DataMigrate::Tasks::DataMigrateTasks.dump
    end

    def initialize(message = nil, pending_migrations: [])
      super(message || pending_migrations_message(pending_migrations))
    end

    private

    def pending_migrations_message(pending_migrations)
      message = +"Data migrations are pending. To resolve this issue, run:\n\n        bin/rails data:migrate\n\n"
      message << "You have #{pending_migrations.size} pending data #{'migration'.pluralize(pending_migrations.size)}:\n\n"
      pending_migrations.each do |pending_migration|
        message << "  %4d %s\n" % [pending_migration[:version], pending_migration[:name]]
      end
      message
    end
  end
end
