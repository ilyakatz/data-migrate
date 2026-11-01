# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::PendingMigrationError do
  describe "#message" do
    it "lists pending migrations like data:abort_if_pending_migrations" do
      error = described_class.new(pending_migrations: [
        { version: 20091231235959, name: "SomeName", kind: :data },
        { version: 20171231235959, name: "SuperUpdate", kind: :data }
      ])

      expect(error.message.strip).to eq(<<~MSG.strip)
        Data migrations are pending. To resolve this issue, run:

                bin/rails data:migrate

        You have 2 pending data migrations:

          20091231235959 SomeName
          20171231235959 SuperUpdate
      MSG
    end

    it "uses the singular form for a single pending migration" do
      error = described_class.new(pending_migrations: [
        { version: 20091231235959, name: "SomeName", kind: :data }
      ])

      expect(error.message).to include("You have 1 pending data migration:\n")
    end

    it "uses the given message when provided" do
      expect(described_class.new("Custom message").message.strip).to eq("Custom message")
    end
  end

  describe "actions" do
    let(:action_name) { "Run pending data migrations" }

    before do
      ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "spec/db/test.db")
      DataMigrate::RailsHelper.schema_migration.create_table
      DataMigrate::RailsHelper.data_schema_migration.create_table
      allow(DataMigrate::Tasks::DataMigrateTasks).to receive(:migrations_paths)
        .and_return(DataMigrate.config.data_migrations_path)
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations") rescue nil
      ActiveRecord::Migration.drop_table("schema_migrations") rescue nil
    end

    it "offers a single action to run pending data migrations" do
      expect(ActiveSupport::ActionableError.actions(described_class).keys).to eq([action_name])
    end

    it "runs the pending data migrations and dumps the data schema" do
      expect(DataMigrate::Tasks::DataMigrateTasks).to receive(:dump)

      ActiveSupport::ActionableError.dispatch(described_class, action_name)

      expect(DataMigrate::RailsHelper.data_schema_migration.normalized_versions.map(&:to_i))
        .to contain_exactly(20091231235959, 20171231235959, 20241231235959)
    end
  end
end
