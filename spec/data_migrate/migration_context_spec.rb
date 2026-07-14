# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::DataMigrator do
  let(:context) { DataMigrate::MigrationContext.new("spec/db/data") }
  let(:schema_context) { ActiveRecord::MigrationContext.new("spec/db/migrate", ar_schema_migration) }
  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end

  before do
    ActiveRecord::Base.establish_connection(db_config)
    DataMigrate::RailsHelper.schema_migration.create_table
    DataMigrate::RailsHelper.data_schema_migration.create_table
  end

  after do
    ActiveRecord::Migration.drop_table("data_migrations") rescue nil
    ActiveRecord::Migration.drop_table("schema_migrations") rescue nil
  end

  describe "migrate" do
    it "migrates existing file" do
      context.migrate(nil)
      context.migrations_status
      versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
      expect(versions.count).to eq(2)
      expect(versions).to include("20091231235959")
      expect(versions).to include("20171231235959")
    end

    it "undo migration" do
      context.migrate(nil)
      context.run(:down, 20171231235959)
      versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
      expect(versions.count).to eq(1)
      expect(versions).to include("20091231235959")
    end

    it "does not do anything if migration is undone twice" do
      context.migrate(nil)
      expect {
        context.run(:down, 20171231235959)
      }.to output(/Undoing SuperUpdate/).to_stdout
      expect {
        context.run(:down, 20171231235959)
      }.not_to output(/Undoing SuperUpdate/).to_stdout
    end

    it "runs a specific migration" do
      context.run(:up, 20171231235959)
      versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
      expect(versions.count).to eq(1)
      expect(versions).to include("20171231235959")
    end

    it "does not do anything if migration is ran twice" do
      expect {
        context.run(:up, 20171231235959)
      }.to output(/Doing SuperUpdate/).to_stdout
      expect {
        context.run(:down, 20171231235959)
      }.not_to output(/Doing SuperUpdate/).to_stdout
    end

    it "alerts for an invalid specific migration" do
      expect {
        context.run(:up, 201712312)
      }.to raise_error(
        ActiveRecord::UnknownMigrationVersionError,
        /No migration with version number 201712312/
      )
    end

    it "rolls back latest migration" do
      context.migrate(nil)
      expect {
        context.rollback
      }.to output(/Undoing SuperUpdate/).to_stdout
      versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
      expect(versions.count).to eq(1)
      expect(versions).to include("20091231235959")
    end

    it "rolls back 2 migrations" do
      context.migrate(nil)
      schema_context.migrate(nil)
      expect {
        context.rollback(2)
      }.to output(/Undoing SomeName/).to_stdout
      versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
      expect(versions.count).to eq(0)
    end

    it "rolls back 2 migrations" do
      context.migrate(nil)
      expect {
        context.rollback(2)
      }.to output(/Undoing SomeName/).to_stdout
      versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
      expect(versions.count).to eq(0)
    end
  end

  describe "db_configuration" do
    context "when db_configuration is not set" do
      it "does not wrap the migration in a temporary connection" do
        expect(DataMigrate::DatabaseTasks).not_to receive(:with_temporary_connection)

        context.run(:up, 20171231235959)

        versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
        expect(versions).to include("20171231235959")
      end
    end

    context "when db_configuration is set" do
      before do
        DataMigrate.configure do |config|
          config.db_configuration = db_config
        end
      end

      it "resolves the configuration and runs actions within a temporary connection" do
        allow(ActiveRecord::Base.configurations).to receive(:resolve).and_call_original
        expect(ActiveRecord::Base.configurations).to receive(:resolve).with(db_config).and_call_original
        expect(DataMigrate::DatabaseTasks).to receive(:with_temporary_connection).and_call_original

        context.run(:up, 20171231235959)

        versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
        expect(versions).to include("20171231235959")
      end

      it "wraps up in a temporary connection" do
        expect(DataMigrate::DatabaseTasks).to receive(:with_temporary_connection).and_call_original

        context.migrate(nil)

        versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
        expect(versions.count).to eq(2)
      end

      it "wraps run in a temporary connection" do
        context.migrate(nil)

        expect(DataMigrate::DatabaseTasks).to receive(:with_temporary_connection).and_call_original

        context.run(:down, 20171231235959)

        versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
        expect(versions).not_to include("20171231235959")
      end
    end
  end

  # schema migration changed in Rails 7.2, from the connection to the pool object.
  def ar_schema_migration
    if ActiveRecord::Base.connection_pool.respond_to?(:schema_migration)
      ActiveRecord::Base.connection_pool.schema_migration
    else
      ActiveRecord::Base.connection.schema_migration
    end
  end
end
