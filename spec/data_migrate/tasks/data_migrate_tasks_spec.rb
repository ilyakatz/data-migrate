# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::Tasks::DataMigrateTasks do
  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end

  before do
    ActiveRecord::Base.establish_connection(db_config)
    DataMigrate::RailsHelper.schema_migration.create_table
    DataMigrate::RailsHelper.data_schema_migration.create_table
  end

  after do
    ActiveRecord::Migration.drop_table("data_migrations") rescue nil
    ActiveRecord::Migration.drop_table("schema_migrations") rescue nil
  end

  describe :dump do
    before do
      allow(DataMigrate::DatabaseTasks).to receive(:db_dir).and_return("spec/db")
      DataMigrate::Tasks::DataMigrateTasks.migrate
    end

    context 'when not given a separate db config' do
      it 'does not override the default connection' do
        expect(ActiveRecord::Base).not_to receive(:establish_connection)
        expect(DataMigrate::SchemaDumper).to receive(:dump)

        DataMigrate::Tasks::DataMigrateTasks.dump
      end
    end

    context 'when given a separate db config' do
      let(:override_config) do
        {
          'host' => '127.0.0.1',
          'database' => 'other_test',
          'adapter' => 'sqlite3',
          'username' => 'root',
          'password' => nil,
        }
      end
      let(:paths) { ["spec/db/migrate"] }

      before do
        DataMigrate.configure do |config|
          config.db_configuration = override_config
        end
      end

      it 'overrides the default connection' do
        expect(ActiveRecord::Base).to receive(:establish_connection).with(override_config)
        DataMigrate::Tasks::DataMigrateTasks.dump
      end
    end
  end

  describe :migrate do
    it "first run should run the first pending migration" do
      expect { DataMigrate::Tasks::DataMigrateTasks.migrate }.to output(/20091231235959 SomeName: migrating/).to_stdout
    end

    it "second run should run the second pending migration" do
      expect { DataMigrate::Tasks::DataMigrateTasks.migrate }.to output(/20171231235959 SuperUpdate: migrating/).to_stdout
    end
  end

  describe :abort_if_pending_migrations do
    subject { DataMigrate::Tasks::DataMigrateTasks.abort_if_pending_migrations(migrations, message) }

    let(:message) { "ABORT_MESSAGE" }

    context "when there are no pending migrations" do
      let(:migrations) { [] }

      it "shouldn't do anything" do
        expect { subject }.to_not raise_error
      end
    end

    context "when there are pending migrations" do
      let(:migrations) do
        [{
          name: "A",
          version: 1
        }, {
          name: 'B',
          version: 2
        }]
      end

      it "should abort with given message and print names and versions of pending migrations" do
        expect { subject }
          .to raise_error(SystemExit, message)
          .and output(match(/You have #{migrations.count} pending migrations:/)
          .and match(Regexp.new(migrations.map { |m| m.slice(:version, :name)
          .values.join("\\W+") }.join("\\W+")))).to_stdout
      end
    end
  end

  describe ".status" do
    before do
      allow(Rails).to receive(:root) { "." }
      allow(Rails).to receive(:application) { OpenStruct.new(config: OpenStruct.new(paths: { "db/migrate" => ["spec/db/migrate"] })) }

      DataMigrate::Tasks::DataMigrateTasks.migrate
    end

    it "should display data migration status" do
      expect {
        DataMigrate::Tasks::DataMigrateTasks.status
      }.to output(/up     20091231235959  Some name/).to_stdout
    end

    it "should display schema and data migration status" do
      expect {
        DataMigrate::Tasks::DataMigrateTasks.status_with_schema
      }.to output(match(/up      data   20091231235959  Some name/)
        .and match(/down    schema  20131111111111  Late migration/)).to_stdout
    end

    context "with migrations in subdirectories" do
      let(:archive_dir) { "spec/db/data/archive" }
      let(:archived_schema_dir) { "spec/db/migrate/archived" }

      before do
        FileUtils.mkdir_p(archive_dir)
        FileUtils.mkdir_p(archived_schema_dir)

        File.write("#{archive_dir}/20101010101010_archived_data.rb", <<~RUBY)
          class ArchivedData < ActiveRecord::Migration[6.1]
          end
        RUBY

        File.write("#{archived_schema_dir}/20121212121212_archived_schema.rb", <<~RUBY)
          class ArchivedSchema < ActiveRecord::Migration[6.1]
          end
        RUBY

        ActiveRecord::Base.connection.execute(<<~SQL.squish)
          INSERT INTO data_migrations (version) VALUES ('20101010101010')
        SQL
      end

      after do
        FileUtils.rm_rf(archive_dir)
        FileUtils.rm_rf(archived_schema_dir)
      end

      it "should find and display data migrations in subdirectories" do
        expect {
          DataMigrate::Tasks::DataMigrateTasks.status
        }.to output(match(/up     20091231235959  Some name/)
          .and match(/up     20101010101010  Archived data/)).to_stdout
      end

      it "should find and display schema migrations in subdirectories" do
        expect {
          DataMigrate::Tasks::DataMigrateTasks.status_with_schema
        }.to output(match(/up      data   20091231235959  Some name/)
          .and match(/up      data   20101010101010  Archived data/)
          .and match(/down    schema  20121212121212  Archived schema/)
          .and match(/down    schema  20131111111111  Late migration/)).to_stdout
      end
    end
  end
end
