require 'spec_helper'

describe DataMigrate::DataMigrator do
  let(:subject) { DataMigrate::DataMigrator }
  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end

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
