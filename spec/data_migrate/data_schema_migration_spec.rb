# frozen_string_literal: true

require 'spec_helper'

describe DataMigrate::DataSchemaMigration do
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
