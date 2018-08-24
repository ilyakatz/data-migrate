# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::DatabaseTasks do
  let(:subject) { DataMigrate::DatabaseTasks }
  let(:migration_path) {
    if Rails::VERSION::MAJOR == 5
      if Rails::VERSION::MINOR == 2
        "spec/db/migrate/5.2"
      else
        "spec/db/migrate/5.0"
      end
    else
      "spec/db/migrate/4.2"
    end
  }
  let(:data_migrations_path) {
    if Rails::VERSION::MAJOR == 5
      if Rails::VERSION::MINOR == 2
        "spec/db/data"
      else
        "spec/db/5.0"
      end
    else
      "spec/db/4.2"
    end
  }
  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end

  before do
    # In a normal Rails installation, db_dir would defer to
    # Rails.application.config.paths["db"].first
    # @see https://github.com/rails/rails/blob/a7d49ef78c36df2d1ca876451f30915ada1079a5/activerecord/lib/active_record/tasks/database_tasks.rb#L54
    allow(subject).to receive(:db_dir).and_return("db")
  end

  describe :schema_file do
    it "returns the correct data schema file path" do
      expect(subject.schema_file).to eq "db/data_schema.rb"
    end
  end

  context "migrations" do
    after do
      begin
        ActiveRecord::Migration.drop_table("data_migrations")
      rescue ActiveRecord::StatementInvalid
      end
      ActiveRecord::Migration.drop_table("schema_migrations")
    end

    before do
      ActiveRecord::Base.establish_connection(db_config)
      ActiveRecord::SchemaMigration.create_table

      allow(DataMigrate::SchemaMigration).to receive(:migrations_paths) {
        migration_path
      }
      allow(DataMigrate::DatabaseTasks).to receive(:data_migrations_path) {
        data_migrations_path
      }.at_least(:once)
      allow(DataMigrate::DatabaseTasks).to receive(:schema_migrations_path) {
        migration_path
      }.at_least(:once)
    end

    describe :past_migrations do
      it do
        subject.forward
        m = subject.past_migrations
        expect(m.count).to eq 1
        expect(m.first[:version]).to eq 20091231235959
      end

      it "shows nothing without any migrations" do
        m = subject.past_migrations
        expect(m.count).to eq 0
      end
    end

    describe :forward do

      it "run forward default amount of times" do
        subject.forward
        versions = DataMigrate::DataSchemaMigration.normalized_versions
        expect(versions.count).to eq(1)
      end

      it "run forward defined number of times" do
        subject.forward(2)
        versions = DataMigrate::DataSchemaMigration.normalized_versions
        expect(versions.count).to eq(1)
        expect(versions.first).to eq "20091231235959"
        versions = ActiveRecord::SchemaMigration.normalized_versions
        expect(versions.count).to eq(1)
        expect(versions.first).to eq "20131111111111"
      end
    end
  end
end
