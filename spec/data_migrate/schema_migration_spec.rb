# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::SchemaMigration do
  let(:migration_path) {
    if Rails::VERSION::MAJOR == 6
      "spec/db/migrate/6.0"
    elsif Rails::VERSION::MAJOR == 5
      if Rails::VERSION::MINOR == 2
        "spec/db/migrate/5.2"
      else
        "spec/db/migrate/5.0"
      end
    else
      "spec/db/migrate/latest"
    end
  }

  let(:subject) { DataMigrate::SchemaMigration }
  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end
  let(:fixture_file_timestamps) do
    %w[20091231235959 20101231235959 20111231235959]
  end

  before do
    ActiveRecord::Base.establish_connection(db_config)
    ActiveRecord::SchemaMigration.create_table
    DataMigrate.config.data_migrations_path = migration_path
  end

  after do
    ActiveRecord::Migration.drop_table("schema_migrations")
  end

  describe :pending_schema_migrations do
    it "list sorted schema migrations" do
      expect(subject).to receive(:migrations_paths) {
        migration_path
      }
      migrations = subject.pending_schema_migrations

      expect(migrations.count).to eq 2
      expect(migrations[0][:version]).to eq(20131111111111)
      expect(migrations[1][:version]).to eq(20202020202011)
    end
  end

  describe :run do
    it do
      expect {
        subject.run(:up, 20202020202011)
      }.to output(/20202020202011 DbMigration: migrating/).to_stdout
      versions = ActiveRecord::SchemaMigration.normalized_versions
      expect(versions.first).to eq("20202020202011")
    end

    it "undo migration" do
      subject.run(:up, 20202020202011)
      expect {
        subject.run(:down, 20202020202011)
      }.to output(/Undoing DbMigration/).to_stdout
      versions = ActiveRecord::SchemaMigration.normalized_versions
      expect(versions.count).to eq(0)
    end
  end

  if Rails.version > '6'
    describe :migrations_paths do
      context 'when a db_name is configured' do
        let(:paths) { ['spec/db/migrate/6.0', 'spec/db/components/migrate/6.0'] }

        if Rails.version > '6.1'
          before do
            allow(ActiveRecord::Base.configurations.configs_for(env_name: 'test', name: 'primary')).to receive(:migrations_paths).and_return(paths)
            DataMigrate.configure do |config|
              config.spec_name = 'primary'
            end
          end
        else
          before do
            allow(ActiveRecord::Base.configurations.configs_for(env_name: 'test', spec_name: 'primary')).to receive(:migrations_paths).and_return(paths)
            DataMigrate.configure do |config|
              config.spec_name = 'primary'
            end
          end
        end

        it 'lists schema migration paths' do
          byebug
          expect(subject.migrations_paths.size).to eq(2)
          expect(subject.migrations_paths).to eq(paths)
        end
      end
    end
  end
end
