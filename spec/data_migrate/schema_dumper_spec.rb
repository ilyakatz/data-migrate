# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::SchemaDumper do
  let(:subject) { DataMigrate::SchemaDumper }
  let(:fixture_file_timestamps) { %w[20091231235959 20101231235959 20111231235959] }

  before do
    ActiveRecord::SchemaMigration.create_table
    DataMigrate::DataSchemaMigration.create_table
    DataMigrate::DataSchemaMigration.create(fixture_file_timestamps.map { |t| { version: t } })
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

      last_version = fixture_file_timestamps.last
      expected = "DataMigrate::Data.define(version: #{last_version})"
      expect(stream.read).to include expected
    end
  end
end
