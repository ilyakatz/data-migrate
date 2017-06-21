require 'spec_helper'

describe DataMigrate::DataMigrator do
  let(:subject) { DataMigrate::DataMigrator }

  describe :assure_data_schema_table do
    it do
      expect(subject).to receive(:db_config) {
        {
          adapter: "sqlite3",
          database: "../db/test.db"
        }
      }.at_least(:once)
      subject.assure_data_schema_table
      binding.pry
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
