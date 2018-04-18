require 'spec_helper'

describe DataMigrate::DataMigrator do

  before do
    unless Rails::VERSION::MAJOR == 5 and
      Rails::VERSION::MINOR == 2
      pending("Tests are only applicable for Rails 5.2")
    end
  end

  after do
    ActiveRecord::Migration.drop_table("data_migrations") rescue nil
  end

  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end

  describe :migrate do
    before do
      ActiveRecord::Base.establish_connection(db_config)
    end

    # it 'migrates existing file' do
    #   context = DataMigrate::MigrationContext.new("spec/db/data")
    #   context.migrate(nil)
    #   context.migrations_status
    #   versions = DataMigrate::DataSchemaMigration.normalized_versions
    #   expect(versions.count).to eq(2)
    #   expect(versions).to include("20091231235959")
    #   expect(versions).to include("20171231235959")
    # end
  end
end
