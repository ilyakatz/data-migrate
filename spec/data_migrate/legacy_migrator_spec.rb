# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::LegacyMigrator do
  let(:context) { DataMigrate::MigrationContext.new("spec/db/data") }

  before do
    ActiveRecord::SchemaMigration.create_table
    DataMigrate::DataSchemaMigration.create_table
  end

  after do
    ActiveRecord::Migration.drop_table("data_migrations") rescue nil
    ActiveRecord::Migration.drop_table("schema_migrations") rescue nil
  end

  it "migrate legacy migrations to be in correct table" do
    # simulate creation of legacy data migration when it was recorded in schema table
    ActiveRecord::SchemaMigration.create(version: "20091231235959")

    # create one migration in correct place
    DataMigrate::DataSchemaMigration.create(version: "20171231235959")

    migrated = DataMigrate::DataMigrator.new(:up, []).load_migrated
    expect(migrated.count).to eq 1

    DataMigrate::LegacyMigrator.new("spec/db/data").migrate

    # after migacy migrator has been run, we should have records of both migrations
    migrated = DataMigrate::DataMigrator .new(:up, []).load_migrated
    expect(migrated.count).to eq 2
  end
end
