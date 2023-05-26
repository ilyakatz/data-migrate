# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::Tasks::DataMigrateTasks do
  describe :dump do
    let(:db_config) do
      {
        adapter: "sqlite3",
        database: "spec/db/other_test.db"
      }
    end

    before do
      allow(DataMigrate::DataMigrator).to receive(:db_config) { db_config }
      allow(DataMigrate::DatabaseTasks).to receive(:db_dir).and_return("spec/db")
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
    end

    context 'when not given a separate db config' do
      it 'does not override the default connection' do
        DataMigrate::Tasks::DataMigrateTasks.migrate
        expect(ActiveRecord::Base).not_to receive(:establish_connection)
        expect(DataMigrate::SchemaDumper).to receive(:dump)
        DataMigrate::Tasks::DataMigrateTasks.dump
      end
    end

    context 'when given ' do
      let(:override_config) do
        {
          'host' => '127.0.0.1',
          'database' => 'other_test',
          'adapter' => 'sqlite3',
          'username' => 'root',
          'password' => nil,
        }
      end

      before do
        DataMigrate.configure do |config|
          config.db_configuration = override_config
        end
      end

      it 'overrides the default connection' do
        DataMigrate::Tasks::DataMigrateTasks.migrate
        expect(ActiveRecord::Base).to receive(:establish_connection).with(override_config)
        DataMigrate::Tasks::DataMigrateTasks.dump
      end
    end
  end

  describe :migrate do
    let(:db_config) do
      {
        adapter: "sqlite3",
        database: "spec/db/test.db"
      }
    end

    before do
      allow(DataMigrate::DataMigrator).to receive(:db_config) { db_config }
      ActiveRecord::Base.establish_connection(db_config)
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
    end

    it do
       expect {
        DataMigrate::Tasks::DataMigrateTasks.migrate
       }.to output(/20091231235959 SomeName: migrating/).to_stdout
    end

    it do
      expect {
        DataMigrate::Tasks::DataMigrateTasks.migrate
      }.to output(/20171231235959 SuperUpdate: migrating/).to_stdout
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
          .and output("You have 2 pending migrations:\n     1 A\n     2 B\n").to_stdout
      end
    end
  end

  describe :status do
    let(:db_config) do
      {
        adapter: "sqlite3",
        database: "spec/db/test.db"
      }
    end

    before do
      hash_config = ActiveRecord::DatabaseConfigurations::HashConfig.new('test', 'test', db_config)
      config_obj = ActiveRecord::DatabaseConfigurations.new([hash_config])
      allow(ActiveRecord::Base).to receive(:configurations).and_return(config_obj)
      allow(Rails).to receive(:root) { '.' }
      allow(DataMigrate::Tasks::DataMigrateTasks).to receive(:schema_migrations_path) { 'spec/db/migrate/6.0' }
      DataMigrate::Tasks::DataMigrateTasks.migrate
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
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
  end
end
