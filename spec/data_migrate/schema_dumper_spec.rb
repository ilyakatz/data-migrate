# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::SchemaDumper do
  let(:subject) { DataMigrate::SchemaDumper }
  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end
  let(:fixture_file_timestamps) do
    %w[20091231235959 20101231235959 20111231235959]
  end

  describe :dump do
    before do
      allow(DataMigrate::DataMigrator).
        to receive(:db_config) { db_config }.at_least(:once)
      ActiveRecord::Base.establish_connection(db_config)

      ActiveRecord::SchemaMigration.create_table
      DataMigrate::DataMigrator.assure_data_schema_table

      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO #{DataMigrate::DataSchemaMigration.table_name}
        VALUES #{fixture_file_timestamps.map { |t| "(#{t})" }.join(', ')}
      SQL
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
    end

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
