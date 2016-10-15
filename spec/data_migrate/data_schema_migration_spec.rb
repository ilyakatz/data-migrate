require 'spec_helper'

describe DataMigrate::DataSchemaMigration do
  let(:subject) { DataMigrate::DataSchemaMigration }
  it "returns correct table name" do
    expect(subject.table_name).to eq("data_migrations")
  end
end
