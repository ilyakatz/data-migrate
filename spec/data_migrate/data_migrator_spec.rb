require 'spec_helper'

describe DataMigrate::DataMigrator do
  let(:subject) { DataMigrate::DataMigrator }
  let(:db_config) {
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  }

  describe :assure_data_schema_table do
    before do
      expect(subject).to receive(:db_config) { db_config }.at_least(:once)
      ActiveRecord::Base.establish_connection(db_config)
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
    end

    it do
      expect(
        ActiveRecord::Base.connection.table_exists?("data_migrations")
      ).to eq false
      subject.assure_data_schema_table
      expect(
        ActiveRecord::Base.connection.table_exists?("data_migrations")
      ).to eq true
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

  describe :match do
    context 'when the file does not match' do
      it 'returns nil' do
        expect(subject.match('not_a_data_migration_file')).to be_nil
      end
    end

    context 'when the file matches' do
      it 'returns a valid MatchData object' do
        match_data = subject.match('20091231235959_some_name.rb')

        expect(match_data[0]).to eq '20091231235959_some_name.rb'
        expect(match_data[1]).to eq '20091231235959'
        expect(match_data[2]).to eq 'some_name'
      end
    end
  end

end

describe DataMigrate::DatabaseTasks do
  let(:subject) { DataMigrate::DatabaseTasks }

  before do
    # In a normal Rails installation, db_dir would defer to Rails.application.config.paths["db"].first
    # @see https://github.com/rails/rails/blob/a7d49ef78c36df2d1ca876451f30915ada1079a5/activerecord/lib/active_record/tasks/database_tasks.rb#L54
    allow(subject).to receive(:db_dir).and_return("db")
  end

  describe :schema_file do
    it "returns the correct data schema file path" do
      expect(subject.schema_file).to eq "db/data_schema.rb"
    end
  end
end

describe DataMigrate::Data do
  let(:subject) { DataMigrate::Data }
  let(:db_config) {
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  }
  let(:fixture_file_timestamps) { [20091231235959, 20101231235959, 20111231235959] }

  around do |example|
    Dir.mktmpdir do |temp_dir|
      @temp_dir = temp_dir

      # create the fake data migration files
      fixture_file_timestamps.each do |timestamp|
        FileUtils.touch File.join(temp_dir, "#{timestamp}_data_migration.rb")
      end

      example.run
    end
  end

  describe :define do
    before do
      expect(DataMigrate::DataMigrator).to receive(:db_config) { db_config }.at_least(:once)
      ActiveRecord::Base.establish_connection(db_config)
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
    end

    context 'when no version is supplied' do
      it 'returns nil' do
        expect(subject.define(version: nil)).to be_nil
      end
    end

    context 'when a version is supplied' do
      before do
        allow(DataMigrate::DataMigrator).to receive(:full_migrations_path).and_return(@temp_dir)
      end

      it 'sets the current version to the supplied version' do
        version = fixture_file_timestamps[1]

        expect(DataMigrate::DataMigrator.current_version).not_to eq version.to_i
        subject.define(version: version)
        expect(DataMigrate::DataMigrator.current_version).to eq version.to_i
      end

      it 'creates entries for migration versions that come before the supplied version' do
        version = fixture_file_timestamps[1]

        subject.define(version: version)

        db_list_data = ActiveRecord::Base.connection.select_values("SELECT version FROM #{DataMigrate::DataMigrator.schema_migrations_table_name}").map(&:to_i)
        expect(db_list_data).to match_array [fixture_file_timestamps[0], fixture_file_timestamps[1]]

        # The last remaining migration (fixture_file_timestamps[2]) was not included as part of the
        # supplied version and so should not appear in the data_migrations table.
        expect(db_list_data).not_to include(fixture_file_timestamps[2])
      end
    end
  end
end

describe DataMigrate::SchemaDumper do
  let(:subject) { DataMigrate::SchemaDumper }
  let(:db_config) {
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  }
  let(:fixture_file_timestamps) { [20091231235959, 20101231235959, 20111231235959] }

  describe :dump do
    before do
      expect(DataMigrate::DataMigrator).to receive(:db_config) { db_config }.at_least(:once)
      ActiveRecord::Base.establish_connection(db_config)

      DataMigrate::DataMigrator.assure_data_schema_table

      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO #{DataMigrate::DataMigrator.schema_migrations_table_name}
        VALUES #{fixture_file_timestamps.map { |t| "(#{t})" }.join(', ')}
      SQL
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
    end

    it 'writes the define method with the version key to the stream' do
      stream = StringIO.new
      DataMigrate::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
      stream.rewind

      expect(stream.read).to include "DataMigrate::Data.define(version: #{fixture_file_timestamps.last})"
    end
  end
end

