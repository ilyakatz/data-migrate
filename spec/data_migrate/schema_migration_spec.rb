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
      "spec/db/migrate/4.2"
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
        subject.run(:up, migration_path, 20202020202011)
      }.to output(/20202020202011 DbMigration: migrating/).to_stdout
      versions = ActiveRecord::SchemaMigration.normalized_versions
      expect(versions.first).to eq("20202020202011")
    end

    it "undo migration" do
      subject.run(:up, migration_path, 20202020202011)
      expect {
        subject.run(:down, migration_path, 20202020202011)
      }.to output(/Undoing DbMigration/).to_stdout
      versions = ActiveRecord::SchemaMigration.normalized_versions
      expect(versions.count).to eq(0)
    end
  end
end
