require "spec_helper"

describe DataMigrate::DataMigrator do
  let(:subject) { DataMigrate::DataMigrator }
  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end

  describe :load_migrated do
    before do
      allow(subject).to receive(:db_config) { db_config }.at_least(:once)
      ActiveRecord::Base.establish_connection(db_config)
      ::ActiveRecord::SchemaMigration.create_table
      DataMigrate::DataSchemaMigration.create_table
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
      ActiveRecord::Migration.drop_table("schema_migrations")
    end

    it do
      subject.assure_data_schema_table
      DataMigrate::DataSchemaMigration.create(version: 20090000000000)
      ::ActiveRecord::SchemaMigration.create(version: 20100000000000)
      DataMigrate::DataSchemaMigration.create(version: 20110000000000)
      ::ActiveRecord::SchemaMigration.create(version: 20120000000000)
      migrated = subject.new(:up, []).load_migrated
      expect(migrated.count).to eq 2
      expect(migrated).to include 20090000000000
      expect(migrated).to include 20110000000000
    end

    it "load legacy migrations" do
      DataMigrate.configure do |config|
        config.schema_data_migrations = true
      end
      subject.assure_data_schema_table
      DataMigrate::DataSchemaMigration.create(version: 20090000000000)
      ::ActiveRecord::SchemaMigration.create(version: 20100000000000)
      DataMigrate::DataSchemaMigration.create(version: 20110000000000)
      ::ActiveRecord::SchemaMigration.create(version: 20120000000000)
      migrated = subject.new(:up, []).load_migrated
      expect(migrated.count).to eq 4
      expect(migrated).to include 20090000000000
      expect(migrated).to include 20110000000000

      DataMigrate.configure do |config|
        config.schema_data_migrations = nil
      end
    end

  end

  describe :assure_data_schema_table do
    before do
      allow(subject).to receive(:db_config) { db_config }.at_least(:once)
      ActiveRecord::Base.establish_connection(db_config)
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
    end

    it do
      expect(
        ActiveRecord::Base.connection.table_exists?("data_migrations")
      ).to eq false
      subject.assure_data_schema_table
      expect(
        ActiveRecord::Base.connection.table_exists?("data_migrations")
      ).to eq true
    end
  end

  describe :match do
    context "when the file does not match" do
      it "returns nil" do
        expect(subject.match("not_a_data_migration_file")).to be_nil
      end
    end

    context "when the file matches" do
      it "returns a valid MatchData object" do
        match_data = subject.match("20091231235959_some_name.rb")

        expect(match_data[0]).to eq "20091231235959_some_name.rb"
        expect(match_data[1]).to eq "20091231235959"
        expect(match_data[2]).to eq "some_name"
      end
    end
  end
end
