# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::StatusService do
  let(:subject) { DataMigrate::StatusService }
  let(:stream) { StringIO.new }
  let(:stream_data) { stream.read }
  let(:connection_db_config) do
    if Gem::Dependency.new("rails", ">= 6.1").match?("rails", Gem.loaded_specs["rails"].version)
      ActiveRecord::Base.connection_db_config
    else
      ActiveRecord::Base.configurations.configs_for.first
    end
  end

  context "table does not exists" do
    before do
      allow_any_instance_of(subject).to receive(:table_name) { "bogus"}

      subject.dump(connection_db_config, stream)
      stream.rewind
    end

    it "show error message" do
      expect(stream_data).to include("Data migrations table does not exist")
    end
  end

  context "table exists" do
    let(:fixture_file_timestamps) do
      %w[20091231235959 20101231235959 20111231235959]
    end

    before do
      ActiveRecord::SchemaMigration.create_table
      DataMigrate::DataSchemaMigration.create_table
      DataMigrate::DataSchemaMigration.create(fixture_file_timestamps.map { |t| { version: t } })

      subject.dump(connection_db_config, stream)
      stream.rewind
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations") rescue nil
      ActiveRecord::Migration.drop_table("schema_migrations") rescue nil
    end

    it "shows successfully executed migration" do
      expected = "   up     20091231235959  Some name"
      expect(stream_data).to include expected
    end

    it "excludes files without .rb extension" do
      expected = "20181128000207  Excluded file"
      expect(stream_data).to_not include expected
    end

    it "shows missing file migration" do
      expected = "   up     20101231235959  ********** NO FILE **********"
      expect(stream_data).to include expected
    end

    it "shows migration that has not run yet" do
      expected = "  down    20171231235959  Super update"
      expect(stream_data).to include expected
    end

    it "outputs migrations in chronological order" do
      expect(stream_data.index("20091231235959")).to be < stream_data.index("20111231235959")
    end
  end
end
