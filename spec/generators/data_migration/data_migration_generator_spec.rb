require 'spec_helper'
require 'rails/generators'
require 'rails/generators/migration'
require 'generators/data_migration/data_migration_generator'

describe DataMigrate::Generators::DataMigrationGenerator do
  let(:subject) { DataMigrate::Generators::DataMigrationGenerator }
  describe :next_migration_number do
    it "next migration" do
      Timecop.freeze("2016-12-03 22:15:26 -0800") do
        if ActiveRecord.version >= Gem::Version.new('7.0')
          expect(ActiveRecord).to receive(:timestamped_migrations) { true }
          expect(subject.next_migration_number(1)).to eq(20161204061526)
        else
          expect(ActiveRecord::Base).to receive(:timestamped_migrations) { true }
          expect(subject.next_migration_number(1)).to eq("20161204061526")
        end
      end
    end
  end

  describe :migration_base_class_name do
    let(:subject) { DataMigrate::Generators::DataMigrationGenerator.new(['my_migration']) }
    it "returns the correct base class name" do
      expect(subject.send(:migration_base_class_name)).to eq("ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]")
    end
  end

  describe :create_data_migration do
    let(:subject) { DataMigrate::Generators::DataMigrationGenerator.new(['my_migration']) }
    let(:data_migrations_file_path) { 'abc/my_migration.rb' }

    context 'when custom data migrations path has a trailing slash' do
      before do
        DataMigrate.config.data_migrations_path = 'abc/'
      end

      it 'returns correct file path' do
        expect(subject).to receive(:migration_template).with(
          'data_migration.rb', data_migrations_file_path
        )

        subject.create_data_migration
      end
    end

    context 'when custom data migrations path does not have a trailing slash' do
      before do
        DataMigrate.config.data_migrations_path = 'abc'
      end

      it 'returns correct file path' do
        expect(subject).to receive(:migration_template).with(
          'data_migration.rb', data_migrations_file_path
        )

        subject.create_data_migration
      end
    end
  end
end
