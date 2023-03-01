require 'spec_helper'

describe DataMigrate::DataSchemaMigration do
  if DataMigrate::RailsHelper.rails_version_equal_to_or_higher_than_7_1
    let(:connection) { double(:connection) }
    let(:subject) { DataMigrate::DataSchemaMigration.new(connection) }

    describe :table_name do
      it "returns correct table name" do
        expect(subject.table_name).to eq("data_migrations")
      end

      describe "when data migrations table name configured" do
        let(:data_migrations_table_name) { "my_app_data_template_migrations"}

        before do
          @before = DataMigrate.config.data_migrations_table_name
          DataMigrate.configure do |config|
            config.data_migrations_table_name = data_migrations_table_name
          end
        end

        after do
          DataMigrate.configure do |config|
            config.data_migrations_table_name = @before
          end
        end

        it "returns correct table name" do
          expect(subject.table_name).to eq(data_migrations_table_name)
        end
      end
    end

    describe :index_name do
      it "returns correct primary key name" do
        expect(subject.primary_key).to eq("version")
      end
    end
  else
    let(:subject) { DataMigrate::DataSchemaMigration }
    describe :table_name do
      it "returns correct table name" do
        expect(subject.table_name).to eq("data_migrations")
      end

      describe "when data migrations table name configured" do
        let(:data_migrations_table_name) { "my_app_data_template_migrations"}

        before do
          @before = DataMigrate.config.data_migrations_table_name
          DataMigrate.configure do |config|
            config.data_migrations_table_name = data_migrations_table_name
          end
        end

        after do
          DataMigrate.configure do |config|
            config.data_migrations_table_name = @before
          end
        end

        it "returns correct table name" do
          expect(subject.table_name).to eq(data_migrations_table_name)
        end
      end
    end

    describe :index_name do
      it "returns correct primary key name" do
        expect(subject.primary_key).to eq("version")
      end
    end
  end
end
