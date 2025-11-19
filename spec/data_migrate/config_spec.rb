# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::Config do
  it "sets default data_migrations_path path", :no_override do
    expect(DataMigrate.config.data_migrations_path).to eq "db/data/"
  end

  it "sets default data_template_path path", :no_override do
    expect(DataMigrate.config.data_template_path).to eq DataMigrate::Config::DEFAULT_DATA_TEMPLATE_PATH
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

  describe "#test_generator_framework=" do
    context "when valid test framework is set" do
      it "sets the test framework" do
        allow(DataMigrate.config).to receive(:test_generator_framework).and_return(:minitest)

        expect(DataMigrate.config.test_generator_framework).to eq(:minitest)
      end
    end

    context "when valid test framework is set" do
      it "sets the test framework" do
        allow(DataMigrate.config).to receive(:test_generator_framework).and_return(:rspec)

        expect(DataMigrate.config.test_generator_framework).to eq(:rspec)
      end
    end

    context "when invalid test framework is set" do
      it "raises an error" do
        expect { DataMigrate.config.test_generator_framework = :invalid }.to raise_error(ArgumentError, "Invalid test generator framework: invalid")
      end
    end
  end
end
