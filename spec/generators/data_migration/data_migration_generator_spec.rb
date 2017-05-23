require 'spec_helper'
require 'rails/generators'
require 'rails/generators/migration'
require 'generators/data_migration/data_migration_generator'

describe DataMigrate::Generators::DataMigrationGenerator do
  let(:subject) { DataMigrate::Generators::DataMigrationGenerator }
  describe :next_migration_number do
    it "next migration" do
      Timecop.freeze("2016-12-03 22:15:26 -0800") do
        expect(ActiveRecord::Base).to receive(:timestamped_migrations) { true }
        expect(subject.next_migration_number(1)).to eq("20161204061526")
      end
    end
  end

  describe :migration_base_class_name do
    let(:subject) { DataMigrate::Generators::DataMigrationGenerator.new(['my_migration']) }
    it "returns the correct base class name" do
      if ActiveRecord.version >= Gem::Version.new('5.0')
        expect(subject.send(:migration_base_class_name)).to eq("ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]")
      else
        expect(subject.send(:migration_base_class_name)).to eq('ActiveRecord::Migration')
      end
    end
  end
end
