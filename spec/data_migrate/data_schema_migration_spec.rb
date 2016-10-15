require 'spec_helper'

describe DataMigrate::DataSchemaMigration do
  let(:subject) { DataMigrate::DataSchemaMigration }
  describe :table_name do
    it "returns correct table name" do
      expect(subject.table_name).to eq("data_migrations")
    end
  end

  describe :index_name do
    it "returns correct index name" do
      expect(subject.index_name).to eq("unique_data_migrations")
    end
  end
end
