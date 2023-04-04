# frozen_string_literal: true
require "spec_helper"

describe DataMigrate::StatusService do
  let(:subject) { DataMigrate::SchemaDumper }
  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end
  let(:service) { DataMigrate::StatusService }

  let(:connection_db_config) do
    if Gem::Dependency.new("rails", ">= 6.1").match?("rails", Gem.loaded_specs["rails"].version)
      ActiveRecord::Base.connection_db_config
    else
      ActiveRecord::Base.configurations.configs_for.first
    end
  end

  context "table does not exists" do
    before do
      ActiveRecord::Base.establish_connection(db_config)
    end

    it "show error message" do
      allow_any_instance_of(service).to receive(:table_name) { "bogus"}
      stream = StringIO.new

      service.dump(connection_db_config, stream)

      stream.rewind
      expected = "Data migrations table does not exist"
      expect(stream.read).to include expected
    end
  end

  context "table exists" do
    let(:fixture_file_timestamps) do
      %w[20091231235959 20101231235959 20111231235959]
    end

    before do
      # allow(DataMigrate::DataMigrator).to receive(:db_config) { db_config }.at_least(:once)
      ActiveRecord::Base.establish_connection(db_config)

      ActiveRecord::SchemaMigration.create_table
      DataMigrate::DataMigrator.assure_data_schema_table

      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO #{DataMigrate::DataSchemaMigration.table_name}
        VALUES #{fixture_file_timestamps.map { |t| "(#{t})" }.join(", ")}
      SQL

      allow_any_instance_of(service).to receive(:root_folder) { "./" }
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
    end

    it "shows successfully executed migration" do
      stream = StringIO.new
      service.dump(connection_db_config, stream)
      stream.rewind

      expected = "   up     20091231235959  Some name"
      expect(stream.read).to include expected
    end

    it "excludes files without .rb extension" do
      stream = StringIO.new
      service.dump(connection_db_config, stream)
      stream.rewind

      expected = "20181128000207  Excluded file"
      expect(stream.read).to_not include expected
    end

    it "shows missing file migration" do
      stream = StringIO.new
      service.dump(connection_db_config, stream)
      stream.rewind

      expected = "   up     20101231235959  ********** NO FILE **********"
      s = stream.read
      expect(s).to include expected
    end

    it "shows migration that has not run yet" do
      stream = StringIO.new
      service.dump(connection_db_config, stream)
      stream.rewind

      expected = "  down    20171231235959  Super update"
      s = stream.read
      expect(s).to include expected
    end

    it "outputs migrations in chronological order" do
      stream = StringIO.new
      service.dump(connection_db_config, stream)
      stream.rewind
      s = stream.read
      expect(s.index("20091231235959")).to be < s.index("20111231235959")
    end
  end
end
