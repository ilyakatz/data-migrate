# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::Tasks::DataMigrateTasks do
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
end
