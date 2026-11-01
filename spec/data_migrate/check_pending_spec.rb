# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

describe DataMigrate::CheckPending do
  let(:app) { ->(_env) { [200, {}, ["ok"]] } }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }
  let(:fixture_migration) { "spec/db/data/20091231235959_some_name.rb" }

  before do
    DataMigrate.configure { |config| config.pending_migration_error = :page_load }
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "spec/db/test.db")
    DataMigrate::RailsHelper.schema_migration.create_table
    DataMigrate::RailsHelper.data_schema_migration.create_table
  end

  after do
    DataMigrate.configure { |config| config.pending_migration_error = nil }
    ActiveRecord::Migration.drop_table("data_migrations") rescue nil
    ActiveRecord::Migration.drop_table("schema_migrations") rescue nil
  end

  def mark_as_migrated(*versions)
    versions.each { |version| DataMigrate::RailsHelper.data_schema_migration.create_version(version.to_s) }
  end

  def configure_data_migrations_path(path)
    DataMigrate.configure { |config| config.data_migrations_path = path }
  end

  it "is not built when pending_migration_error is not :page_load" do
    DataMigrate.configure { |config| config.pending_migration_error = nil }

    expect(middleware).to be(app)
  end

  it "raises a PendingMigrationError listing the pending data migrations" do
    mark_as_migrated(20091231235959)

    expect { middleware.call(env) }.to raise_error(DataMigrate::PendingMigrationError) { |error|
      expect(error.message).to include("20171231235959 SuperUpdate")
      expect(error.message).to include("20241231235959 DataTwoUpdate")
      expect(error.message).not_to include("SomeName")
    }
  end

  it "calls the app when no data migrations are pending" do
    mark_as_migrated(20091231235959, 20171231235959, 20241231235959)

    expect(middleware.call(env)).to eq([200, {}, ["ok"]])
  end

  it "does not check again while the data migration files are unchanged" do
    mark_as_migrated(20091231235959, 20171231235959, 20241231235959)
    allow(DataMigrate::DatabaseTasks).to receive(:pending_data_migrations).and_call_original

    2.times { middleware.call(env) }

    expect(DataMigrate::DatabaseTasks).to have_received(:pending_data_migrations).once
  end

  it "checks on every request while data migrations are pending" do
    expect { middleware.call(env) }.to raise_error(DataMigrate::PendingMigrationError)

    mark_as_migrated(20091231235959, 20171231235959, 20241231235959)

    expect(middleware.call(env)).to eq([200, {}, ["ok"]])
  end

  context "with a temporary data migrations directory" do
    around do |example|
      Dir.mktmpdir { |dir| @dir = dir; example.run }
    end

    it "checks again when a new data migration file is added" do
      configure_data_migrations_path(@dir)
      expect(middleware.call(env)).to eq([200, {}, ["ok"]])

      FileUtils.cp(fixture_migration, @dir)

      expect { middleware.call(env) }.to raise_error(DataMigrate::PendingMigrationError, /SomeName/)
    end

    it "supports a data migrations path with a trailing slash" do
      configure_data_migrations_path("#{@dir}/")
      expect(middleware.call(env)).to eq([200, {}, ["ok"]])

      FileUtils.cp(fixture_migration, @dir)

      expect { middleware.call(env) }.to raise_error(DataMigrate::PendingMigrationError, /SomeName/)
    end

    it "supports a Pathname data migrations path" do
      configure_data_migrations_path(Pathname.new(@dir))
      expect(middleware.call(env)).to eq([200, {}, ["ok"]])

      FileUtils.cp(fixture_migration, @dir)

      expect { middleware.call(env) }.to raise_error(DataMigrate::PendingMigrationError, /SomeName/)
    end

    it "calls the app when the data migrations directory does not exist" do
      configure_data_migrations_path(File.join(@dir, "missing"))

      expect(middleware.call(env)).to eq([200, {}, ["ok"]])
    end
  end
end
