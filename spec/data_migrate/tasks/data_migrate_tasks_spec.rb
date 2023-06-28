# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::Tasks::DataMigrateTasks do
  let(:connection_db_config) do
    if Gem::Dependency.new("railties", ">= 6.1").match?("railties", Gem.loaded_specs["railties"].version)
      ActiveRecord::Base.connection_db_config
    else
      ActiveRecord::Base.configurations.configs_for.first
    end
  end

  before do
    ActiveRecord::SchemaMigration.create_table
    DataMigrate::DataSchemaMigration.create_table
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
  end
end
