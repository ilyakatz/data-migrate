require "spec_helper"

describe DataMigrate::DataMigrator do
  let(:context) {
    DataMigrate::MigrationContext.new("spec/db/data")
  }

  before do
    unless Rails::VERSION::MAJOR == 5 and
           Rails::VERSION::MINOR == 2
      skip("Tests are only applicable for Rails 5.2")
    end
  end

  after do
    begin
      ActiveRecord::Migration.drop_table("data_migrations")
    rescue StandardError
      nil
    end
  end

  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end

  describe :migrate do
    before do
      ActiveRecord::Base.establish_connection(db_config)
      ActiveRecord::SchemaMigration.create_table
    end

    it "migrates existing file" do
      context.migrate(nil)
      context.migrations_status
      versions = DataMigrate::DataSchemaMigration.normalized_versions
      expect(versions.count).to eq(2)
      expect(versions).to include("20091231235959")
      expect(versions).to include("20171231235959")
    end

    it "undo migration" do
      context.migrate(nil)
      context.run(:down, 20171231235959)
      versions = DataMigrate::DataSchemaMigration.normalized_versions
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
      versions = DataMigrate::DataSchemaMigration.normalized_versions
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
      versions = DataMigrate::DataSchemaMigration.normalized_versions
      expect(versions.count).to eq(1)
      expect(versions).to include("20091231235959")
    end

    it "rolls back 2 migrations" do
      context.migrate(nil)
      expect {
        context.rollback(2)
      }.to output(/Undoing SomeName/).to_stdout
      versions = DataMigrate::DataSchemaMigration.normalized_versions
      expect(versions.count).to eq(0)
    end
  end
end
