require 'spec_helper'
require 'rails/generators'
require 'rails/generators/migration'
require 'generators/data_migration/data_migration_generator'

describe DataMigrate::Generators::DataMigrationGenerator do
  subject { DataMigrate::Generators::DataMigrationGenerator }

  describe :next_migration_number do
    it "next migration" do
      Timecop.freeze("2016-12-03 22:15:26 -0800") do
        if ActiveRecord.version >= Gem::Version.new('7.0')
          expect(ActiveRecord).to receive(:timestamped_migrations) { true }
        else
          expect(ActiveRecord::Base).to receive(:timestamped_migrations) { true }
        end
        expect(subject.next_migration_number(1).to_s).to eq("20161204061526")
      end
    end
  end

  describe :migration_base_class_name do
    subject { generator.send(:migration_base_class_name) }

    let(:generator) { DataMigrate::Generators::DataMigrationGenerator.new(['my_migration']) }

    it "returns the correct base class name" do
      is_expected.to eq("ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]")
    end
  end

  describe :create_data_migration do
    let(:migration_name) { 'my_migration' }

    subject { DataMigrate::Generators::DataMigrationGenerator.new([migration_name]) }

    let(:data_migrations_file_path) { "abc/#{migration_name}.rb" }

    context 'when custom data migrations path has a trailing slash' do
      before do
        DataMigrate.config.data_migrations_path = 'abc/'
      end

      it 'returns correct file path' do
        is_expected.to receive(:migration_template).with(
          'data_migration.rb', data_migrations_file_path
        )

        expect(subject).not_to receive(:template)

        subject.create_data_migration
      end
    end

    context 'when custom data migrations path does not have a trailing slash' do
      before do
        DataMigrate.config.data_migrations_path = 'abc'
      end

      it 'returns correct file path' do
        is_expected.to receive(:migration_template).with(
          'data_migration.rb', data_migrations_file_path
        )

        expect(subject).not_to receive(:template)

        subject.create_data_migration
      end
    end

    context 'when test support is enabled' do
      let(:rails_root) { 'dummy-app' }

      before do
        DataMigrate.config.data_migrations_path = 'db/data/'
        DataMigrate.config.test_support_enabled = true

        allow(Rails).to receive(:root).and_return(Pathname.new(rails_root))
        expect(DataMigrate::Helpers::InferTestSuiteType).to receive(:new).and_return(infer_double)
      end

      context 'and the test suite is RSpec' do
        let(:infer_double) { instance_double(DataMigrate::Helpers::InferTestSuiteType, call: :rspec) }

        it 'creates a spec file' do
          expect(subject).to receive(:template).with(
            'data_migration_spec.rb',
            "#{rails_root}/spec/db/data/#{migration_name}_spec.rb"
          )

          subject.create_data_migration
        end
      end

      context 'and the test suite is Minitest' do
        let(:infer_double) { instance_double(DataMigrate::Helpers::InferTestSuiteType, call: :minitest) }

        it 'creates a test file' do
          expect(subject).to receive(:template).with(
            'data_migration_test.rb',
            "#{rails_root}/test/db/data/#{migration_name}_test.rb"
          )

          subject.create_data_migration
        end
      end
    end
  end

  describe ".source_root" do
    subject { described_class.source_root }

    let(:default_source_root) do
      File.expand_path(
        File.dirname(File.join(DataMigrate.root, "generators", "data_migration", "templates", "data_migration.rb"))
      )
    end

    it { is_expected.to eq default_source_root }

    context "when DateMigrate.config.data_template_path is set" do
      before do
        @before = DataMigrate.config.data_template_path
        DataMigrate.configure do |config|
          config.data_template_path = data_template_path
        end
      end

      let(:data_template_path) do
        File.join(DataMigrate.root, "generators", "data_migration", "templates", "data_migration.rb")
      end
      let(:expected_source_root) { File.dirname(data_template_path) }

      after do
        DataMigrate.configure do |config|
          config.data_template_path = @before
        end
      end

      it "reads directory from config data template path" do
        is_expected.to eq expected_source_root
      end
    end
  end
end
