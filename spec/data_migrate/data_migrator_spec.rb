require 'spec_helper'

describe DataMigrate::DataMigrator do
  let(:subject) { DataMigrate::DataMigrator }
  let(:db_config) {
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  }

  describe :assure_data_schema_table do
    before do
      expect(subject).to receive(:db_config) { db_config }.at_least(:once)
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

  describe :schema_migrations_table_name do
    it "returns correct table name" do
      expect(subject.schema_migrations_table_name).to eq("data_migrations")
    end
  end

  describe :migrations_path do
    it "returns correct migrations path" do
      expect(subject.migrations_path).to eq("db/data")
    end
  end

end
