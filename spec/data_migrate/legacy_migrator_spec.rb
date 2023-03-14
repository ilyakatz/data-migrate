require "spec_helper"

describe DataMigrate::LegacyMigrator do
  let(:context) {
    DataMigrate::MigrationContext.new("spec/db/data")
  }

  after do
    begin
      ActiveRecord::Migration.drop_table("data_migrations")
      ActiveRecord::Migration.drop_table("schema_migrations")
    rescue StandardError
      nil
    end
  end

  before do
    ActiveRecord::Base.establish_connection(db_config)
    ActiveRecord::Base.connection.schema_migration.create_table
    DataMigrate::DataSchemaMigration.create_table
  end

  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end

  it "migrate legacy migrations to be in correct table" do
    DataMigrate::DataSchemaMigration.create_table
    # simulate creation of legacy data migration when
    # it was recorded in schema table
    ActiveRecord::SchemaMigration.create(version: "20091231235959")

    # create one migration in correct place
    DataMigrate::DataSchemaMigration.create(version: "20171231235959")

    migrated = DataMigrate::DataMigrator .new(:up, []).load_migrated
    expect(migrated.count).to eq 1

    DataMigrate::LegacyMigrator.new("spec/db/data").migrate

    # after migacy migrator has been run, we should have records
    # of both migrations
    migrated = DataMigrate::DataMigrator .new(:up, []).load_migrated
    expect(migrated.count).to eq 2
  end

end
