# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::SchemaDumper do
  let(:subject) { DataMigrate::SchemaDumper }
  let(:fixture_file_timestamps) do
    %w[20091231235959 20101231235959 20111231235959]
  end

  before do
    DataMigrate::RailsHelper.schema_migration.create_table
    DataMigrate::RailsHelper.data_schema_migration.create_table

    fixture_file_timestamps.map do |t|
      DataMigrate::RailsHelper.data_schema_migration.create_version(t)
    end
  end

  after do
    ActiveRecord::Migration.drop_table("data_migrations") rescue nil
    ActiveRecord::Migration.drop_table("schema_migrations") rescue nil
  end

  describe ".dump" do
    it "writes the define method with the version key to the stream" do
      stream = StringIO.new
      DataMigrate::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
      stream.rewind

      last_version = fixture_file_timestamps.last.dup.insert(4, "_").insert(7, "_").insert(10, "_")
      expected = "DataMigrate::Data.define(version: #{last_version})"
      expect(stream.read).to include expected
    end
  end
end
