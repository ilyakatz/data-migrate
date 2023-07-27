require 'spec_helper'

describe DataMigrate::DataSchemaMigration do
  if DataMigrate::RailsHelper.rails_version_equal_to_or_higher_than_7_1
    let(:connection) { double(:connection) }
    let(:subject) { DataMigrate::DataSchemaMigration.new(connection) }

    describe :table_name do
      it "returns correct table name" do
        expect(subject.table_name).to eq("data_migrations")
      end
    end

    describe :index_name do
      it "returns correct primary key name" do
        expect(subject.primary_key).to eq("version")
      end
    end
  else
    let(:subject) { DataMigrate::DataSchemaMigration }
    describe :table_name do
      it "returns correct table name" do
        expect(subject.table_name).to eq("data_migrations")
      end
    end

    describe :index_name do
      it "returns correct primary key name" do
        expect(subject.primary_key).to eq("version")
      end
    end
  end
end
