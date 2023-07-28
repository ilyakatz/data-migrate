# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::DatabaseTasks do
  let(:subject) { DataMigrate::DatabaseTasks }
  let(:migration_path) { "spec/db/migrate" }
  let(:data_migrations_path) {
    DataMigrate.config.data_migrations_path
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
    allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:db_dir).and_return("db")
  end

  before do
    allow(DataMigrate::Tasks::DataMigrateTasks).to receive(:migrations_paths) {
      data_migrations_path
    }
    ActiveRecord::Base.establish_connection(db_config)
    hash_config = ActiveRecord::DatabaseConfigurations::HashConfig.new('test', 'test', db_config)
    config_obj = ActiveRecord::DatabaseConfigurations.new([hash_config])
    allow(ActiveRecord::Base).to receive(:configurations).and_return(config_obj)
  end

  context "migrations" do
    after do
      ActiveRecord::Migration.drop_table("data_migrations") rescue nil
      ActiveRecord::Migration.drop_table("schema_migrations") rescue nil
    end

    before do
      DataMigrate::RailsHelper.schema_migration.create_table

      allow(DataMigrate::SchemaMigration).to receive(:migrations_paths) {
        migration_path
      }
      allow(DataMigrate::DatabaseTasks).to receive(:data_migrations_path) {
        data_migrations_path
      }.at_least(:once)
    end

    describe :past_migrations do
      it "returns past migration records" do
        subject.forward
        migrations = subject.past_migrations
        expect(migrations.count).to eq 1
        expect(migrations.first[:version]).to eq 20091231235959
      end

      it "shows nothing without any migrations" do
        migrations = subject.past_migrations
        expect(migrations.count).to eq 0
      end
    end

    describe :forward do

      it "run forward default amount of times" do
        subject.forward
        versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
        expect(versions.count).to eq(1)
      end

      it "run forward defined number of times" do
        subject.forward(2)
        versions = DataMigrate::RailsHelper.data_schema_migration.normalized_versions
        expect(versions.count).to eq(1)
        expect(versions.first).to eq "20091231235959"
        versions = DataMigrate::RailsHelper.schema_migration.normalized_versions
        expect(versions.count).to eq(1)
        expect(versions.first).to eq "20131111111111"
      end
    end
  end
end
