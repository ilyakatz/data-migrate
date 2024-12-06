# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::DatabaseTasks do
  let(:subject) { DataMigrate::DatabaseTasks }
  let(:migration_path) { "spec/db/migrate" }
  let(:data_migrations_path) { DataMigrate.config.data_migrations_path }

  before do
    # In a normal Rails installation, db_dir would defer to
    # Rails.application.config.paths["db"].first
    # @see https://github.com/rails/rails/blob/a7d49ef78c36df2d1ca876451f30915ada1079a5/activerecord/lib/active_record/tasks/database_tasks.rb#L54
    allow(subject).to receive(:db_dir).and_return("db")
    allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:db_dir).and_return("db")
  end

  before do
    allow(DataMigrate::Tasks::DataMigrateTasks).to receive(:migrations_paths) do
      data_migrations_path
    end
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "spec/db/test.db")
    hash_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
      'test', 'test', adapter: "sqlite3", database: "spec/db/test.db"
    )
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

      allow(DataMigrate::SchemaMigration).to receive(:migrations_paths) { migration_path }
      allow(DataMigrate::DatabaseTasks).to receive(:data_migrations_path) do
        data_migrations_path
      end.at_least(:once)
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

    if DataMigrate::RailsHelper.rails_version_equal_to_or_higher_than_7_0
      describe :schema_dump_path do
        before do
          allow(ActiveRecord::Base).to receive(:configurations)
            .and_return(ActiveRecord::DatabaseConfigurations.new([db_config]))
        end

        context "for primary database" do
          let(:db_config) do
            ActiveRecord::DatabaseConfigurations::HashConfig.new("development", "primary", {})
          end

          context "for :ruby db format" do
            it 'returns the data schema path' do
              allow(ActiveRecord).to receive(:schema_format).and_return(:ruby)
              expect(subject.schema_dump_path(db_config)).to eq("db/data_schema.rb")
            end
          end

          context "for :sql db format" do
            it 'returns the data schema path' do
              allow(ActiveRecord).to receive(:schema_format).and_return(:sql)
              expect(subject.schema_dump_path(db_config, :sql)).to eq("db/data_schema.rb")
            end
          end
        end
      end
    end

    describe :prepare_all_with_data do
      let(:db_config) do
        ActiveRecord::DatabaseConfigurations::HashConfig.new(
          'test',
          'primary',
          adapter: "sqlite3",
          database: "spec/db/test.db"
        )
      end

      let(:pool) { double("ConnectionPool") }
      let(:connection) { double("Connection") }

      before do
        allow(subject).to receive(:each_current_configuration).and_yield(db_config)
        allow(subject).to receive(:with_temporary_pool).with(db_config).and_yield(pool)
        allow(pool).to receive(:lease_connection).and_return(connection)
        allow(subject).to receive(:schema_dump_path).and_return("db/data_schema.rb")
        allow(File).to receive(:exist?).and_return(true)
        allow(subject).to receive(:load_schema)
        allow(subject).to receive(:load_schema_current)
        allow(subject).to receive(:migrate_with_data)
        allow(subject).to receive(:dump_schema)
        allow(DataMigrate::Tasks::DataMigrateTasks).to receive(:dump)
        allow(subject).to receive(:load_seed)

        configurations = ActiveRecord::DatabaseConfigurations.new([db_config])
        allow(ActiveRecord::Base).to receive(:configurations).and_return(configurations)
      end

      context "when the database does not exist" do
        before do
          allow(subject).to receive(:database_exists?).with(connection).and_return(false)
          allow_any_instance_of(ActiveRecord::Tasks::DatabaseTasks).to receive(:create)
            .and_return(true)
        end

        it "creates the database" do
          expect_any_instance_of(ActiveRecord::Tasks::DatabaseTasks).to receive(:create)
            .with(db_config)
          subject.prepare_all_with_data
        end

        it "loads the schema" do
          expect(subject).to receive(:load_schema).with(
            db_config,
            subject.send(:schema_format),
            nil
          )
          subject.prepare_all_with_data
        end

        it "loads the current data schema" do
          expect(subject).to receive(:load_schema_current).with(:ruby, ENV["DATA_SCHEMA"])
          subject.prepare_all_with_data
        end

        it "runs migrations with data" do
          expect(subject).to receive(:migrate_with_data)
          subject.prepare_all_with_data
        end

        it "dumps the schema after migration" do
          expect(subject).to receive(:dump_schema).with(db_config)
          expect(DataMigrate::Tasks::DataMigrateTasks).to receive(:dump)
          subject.prepare_all_with_data
        end

        it "loads seed data" do
          expect(subject).to receive(:load_seed)
          subject.prepare_all_with_data
        end
      end

      context "when the database exists" do
        before do
          allow(subject).to receive(:database_exists?).with(connection).and_return(true)
        end

        it "does not create the database" do
          expect(ActiveRecord::Tasks::DatabaseTasks).not_to receive(:create)
          subject.prepare_all_with_data
        end

        it "does not load the schema" do
          expect(subject).not_to receive(:load_schema)
          expect(subject).not_to receive(:load_schema_current)
          subject.prepare_all_with_data
        end

        it "runs migrations with data" do
          expect(subject).to receive(:migrate_with_data)
          subject.prepare_all_with_data
        end

        it "dumps the schema after migration" do
          expect(subject).to receive(:dump_schema).with(db_config)
          expect(DataMigrate::Tasks::DataMigrateTasks).to receive(:dump)
          subject.prepare_all_with_data
        end

        it "does not load seed data" do
          expect(subject).not_to receive(:load_seed)
          subject.prepare_all_with_data
        end
      end
    end
  end
end
