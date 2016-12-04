require 'spec_helper'
require 'rails/generators'
require 'rails/generators/migration'
require 'generators/data_migration/data_migration_generator'

describe DataMigrate::Generators::DataMigrationGenerator do
  let(:subject) { DataMigrate::Generators::DataMigrationGenerator }
  describe :next_migration_number do
    context "timed migration is turned off" do
      it "next migration" do
        expect(ActiveRecord::Base).to receive(:timestamped_migrations) { false }
        expect(subject).to receive(:current_migration_number).and_return(
          20171204060529
        )
        expect(subject.next_migration_number(1)).to eq("20171204060530")
      end
    end

    context "timed migration is turned on" do
      it "next migration" do
        Timecop.freeze("2016-12-03 22:15:26 -0800") do
          expect(ActiveRecord::Base).to receive(:timestamped_migrations) { true }
          expect(subject).not_to receive(:current_migration_number)
          expect(subject.next_migration_number(1)).to eq("20161204061526")
        end
      end
    end
  end
end
