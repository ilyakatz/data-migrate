# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::Config do
  it "sets default data_migrations_path path", :no_override do
    expect(DataMigrate.config.data_migrations_path).to eq "db/data/"
  end

  it "sets default data_template_path path", :no_override do
    expect(DataMigrate.config.data_template_path).to eq DataMigrate::Config::DEFAULT_DATA_TEMPLATE_PATH
  end

  it "disables pending_migration_error by default", :no_override do
    expect(DataMigrate.config.pending_migration_error).to be_nil
  end

  describe "pending migration error configured" do
    subject { DataMigrate.config.pending_migration_error }

    before do
      @original_pending_migration_error = DataMigrate.config.pending_migration_error

      DataMigrate.configure do |config|
        config.pending_migration_error = :page_load
      end
    end

    after do
      DataMigrate.configure do |config|
        config.pending_migration_error = @original_pending_migration_error
      end
    end

    it "equals the configured value" do
      is_expected.to eq(:page_load)
    end
  end

  describe "data migration path configured" do
    subject { DataMigrate.config.data_migrations_path }
    let(:data_migrations_path) { "db/awesome/" }

    before do
      @original_data_migrations_path = DataMigrate.config.data_migrations_path

      DataMigrate.configure do |config|
        config.data_migrations_path = data_migrations_path
      end
    end

    after do
      DataMigrate.configure do |config|
        config.data_migrations_path = @original_data_migrations_path
      end
    end

    it "equals the custom data migration path" do
      is_expected.to eq(data_migrations_path)
    end
  end

  describe "data template path configured" do
    subject { DataMigrate.config.data_template_path }
    let(:data_template_path) { File.join(DataMigrate.root, "generators", "data_migration", "templates", "data_migration.rb") }

    before do
      @original_data_migrations_path = DataMigrate.config.data_template_path

      DataMigrate.configure do |config|
        config.data_template_path = data_template_path
      end
    end

    after do
      DataMigrate.configure do |config|
        config.data_template_path = @original_data_migrations_path
      end
    end

    it "equals the custom data template path" do
      is_expected.to eq data_template_path
    end

    context "when path does not exist" do
      subject { DataMigrate.config.data_template_path = invalid_path }

      let(:invalid_path) { "lib/awesome/templates/data_migration.rb" }

      it "checks that file exists on setting config var" do
        expect { subject }.to raise_error { ArgumentError.new("File not found: '#{data_template_path}'") }
      end
    end
  end
end
