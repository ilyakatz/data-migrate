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

    describe "structure_dump_flags delegation" do
      it "delegates structure_dump_flags to ActiveRecord::Tasks::DatabaseTasks" do
        original_flags = ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags
        begin
          ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = { postgresql: "--no-comments" }
          expect(subject.structure_dump_flags).to eq({ postgresql: "--no-comments" })
        ensure
          ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = original_flags
        end
      end

      it "delegates structure_load_flags to ActiveRecord::Tasks::DatabaseTasks" do
        original_flags = ActiveRecord::Tasks::DatabaseTasks.structure_load_flags
        begin
          ActiveRecord::Tasks::DatabaseTasks.structure_load_flags = { postgresql: "--quiet" }
          expect(subject.structure_load_flags).to eq({ postgresql: "--quiet" })
        ensure
          ActiveRecord::Tasks::DatabaseTasks.structure_load_flags = original_flags
        end
      end

      it "returns nil when structure_dump_flags is not set" do
        original_flags = ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags
        begin
          ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = nil
          expect(subject.structure_dump_flags).to be_nil
        ensure
          ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = original_flags
        end
      end

      it "returns nil when structure_load_flags is not set" do
        original_flags = ActiveRecord::Tasks::DatabaseTasks.structure_load_flags
        begin
          ActiveRecord::Tasks::DatabaseTasks.structure_load_flags = nil
          expect(subject.structure_load_flags).to be_nil
        ensure
          ActiveRecord::Tasks::DatabaseTasks.structure_load_flags = original_flags
        end
      end

      context "when dump_schema calls structure_dump_flags_for" do
        # This test ensures that the structure_dump_flags delegation works correctly
        # when dump_schema is called with :sql format, which uses structure_dump internally.
        # Without the delegation, this raises:
        # NameError: undefined local variable or method 'structure_dump_flags' for module primary
        it "does not raise NameError when accessing structure_dump_flags" do
          db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
            'test',
            'primary',
            adapter: "sqlite3",
            database: "spec/db/test.db"
          )

          # Verify the delegation methods are accessible and don't raise errors
          expect { subject.structure_dump_flags }.not_to raise_error
          expect { subject.structure_load_flags }.not_to raise_error

          # These methods should return the same values as ActiveRecord::Tasks::DatabaseTasks
          expect(subject.structure_dump_flags).to eq(ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags)
          expect(subject.structure_load_flags).to eq(ActiveRecord::Tasks::DatabaseTasks.structure_load_flags)
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
      let(:ar_schema_path) { "db/structure.sql" }
      let(:data_schema_path) { "db/data_schema.rb" }

      before do
        allow(subject).to receive(:each_current_configuration).and_yield(db_config)
        allow(subject).to receive(:with_temporary_pool).with(db_config).and_yield(pool)
        allow(pool).to receive(:lease_connection).and_return(connection)
        allow(subject).to receive(:schema_dump_path).and_return(data_schema_path)
        allow(subject).to receive(:schema_format).and_return(:sql)
        allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:schema_dump_path)
          .with(db_config, :sql).and_return(ar_schema_path)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(ar_schema_path).and_return(true)
        allow(File).to receive(:exist?).with(data_schema_path).and_return(true)
        allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:load_schema)
        allow(subject).to receive(:load_schema_current)
        allow(subject).to receive(:migrate_with_data)
        allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:dump_schema)
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

        it "loads the ActiveRecord schema via ActiveRecord::Tasks::DatabaseTasks" do
          expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:load_schema).with(
            db_config,
            :sql,
            ar_schema_path
          )
          subject.prepare_all_with_data
        end

        it "loads the current data schema as ruby" do
          expect(subject).to receive(:load_schema_current).with(:ruby, ENV["DATA_SCHEMA"])
          subject.prepare_all_with_data
        end

        it "does not load data_schema.rb as sql" do
          expect(ActiveRecord::Tasks::DatabaseTasks).not_to receive(:load_schema).with(
            db_config,
            :sql,
            data_schema_path
          )
          expect(subject).not_to receive(:load_schema)
          subject.prepare_all_with_data
        end

        it "runs migrations with data" do
          expect(subject).to receive(:migrate_with_data)
          subject.prepare_all_with_data
        end

        it "dumps the ActiveRecord schema and data schema after migration" do
          expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:dump_schema).with(db_config)
          expect(DataMigrate::Tasks::DataMigrateTasks).to receive(:dump)
          subject.prepare_all_with_data
        end

        it "loads seed data" do
          expect(subject).to receive(:load_seed)
          subject.prepare_all_with_data
        end

        context "when only the ActiveRecord schema exists" do
          before do
            allow(File).to receive(:exist?).with(data_schema_path).and_return(false)
          end

          it "loads the ActiveRecord schema but not the data schema" do
            expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:load_schema).with(
              db_config,
              :sql,
              ar_schema_path
            )
            expect(subject).not_to receive(:load_schema_current)
            subject.prepare_all_with_data
          end
        end

        context "when only the data schema exists" do
          before do
            allow(File).to receive(:exist?).with(ar_schema_path).and_return(false)
          end

          it "loads the data schema but not the ActiveRecord schema" do
            expect(ActiveRecord::Tasks::DatabaseTasks).not_to receive(:load_schema)
            expect(subject).to receive(:load_schema_current).with(:ruby, ENV["DATA_SCHEMA"])
            subject.prepare_all_with_data
          end
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
          expect(ActiveRecord::Tasks::DatabaseTasks).not_to receive(:load_schema)
          expect(subject).not_to receive(:load_schema_current)
          subject.prepare_all_with_data
        end

        it "runs migrations with data" do
          expect(subject).to receive(:migrate_with_data)
          subject.prepare_all_with_data
        end

        it "dumps the ActiveRecord schema and data schema after migration" do
          expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:dump_schema).with(db_config)
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
