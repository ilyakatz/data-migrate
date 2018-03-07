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
    if Rails::VERSION::MAJOR == 5
      if Rails::VERSION::MINOR == 2
        allow(DataMigrate::Tasks::DataMigrateTasks).to receive(:migrations_paths) {
          "spec/db/data"
        }
      else
        allow(DataMigrate::Tasks::DataMigrateTasks).to receive(:migrations_paths) {
          "spec/db/5.0"
        }
      end
    else
      allow(DataMigrate::Tasks::DataMigrateTasks).to receive(:migrations_paths) {
        "spec/db/4.2"
      }
    end
    allow(DataMigrate::DataMigrator).to receive(:db_config) { db_config }
    ActiveRecord::Base.establish_connection(db_config)
  end

  after do
    ActiveRecord::Migration.drop_table("data_migrations")
  end

  describe :migrate do
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
end
