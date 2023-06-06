# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::SchemaMigration do
  let(:subject) { DataMigrate::SchemaMigration }
  let(:migration_path) { "spec/db/migrate" }
  let(:fixture_file_timestamps) do
    %w[20091231235959 20101231235959 20111231235959]
  end

  before do
    ActiveRecord::SchemaMigration.create_table
    DataMigrate::DataSchemaMigration.create_table
  end

  after do
    ActiveRecord::Migration.drop_table("data_migrations") rescue nil
    ActiveRecord::Migration.drop_table("schema_migrations") rescue nil
  end

  describe :pending_schema_migrations do
    it "list sorted schema migrations" do
      expect(subject).to receive(:migrations_paths) {
        migration_path
      }

      migrations = subject.pending_schema_migrations

      expect(migrations.count).to eq 2
      expect(migrations[0][:version]).to eq(20131111111111)
      expect(migrations[1][:version]).to eq(20202020202011)
    end
  end

  describe :run do
    it "can run up task" do
      expect {
        subject.run(:up, migration_path, 20202020202011)
      }.to output(/20202020202011 DbMigration: migrating/).to_stdout
      versions = ActiveRecord::SchemaMigration.normalized_versions
      expect(versions.first).to eq("20202020202011")
    end

    it "can run down task" do
      subject.run(:up, migration_path, 20202020202011)

      expect {
        subject.run(:down, migration_path, 20202020202011)
      }.to output(/Undoing DbMigration/).to_stdout

      versions = ActiveRecord::SchemaMigration.normalized_versions

      expect(versions.count).to eq(0)
    end
  end

  describe :migrations_paths do
    context 'when a db_name is configured' do
      let(:config) { double(:config) }
      let(:paths) { ['spec/db/migrate', 'spec/db/migrate/other'] }
      let(:specification_name) { "primary" }
      let(:config_options) do
        if Gem::Dependency.new("rails", "~> 6.0").match?("rails", Gem.loaded_specs["rails"].version)
          { env_name: Rails.env, spec_name: specification_name }
        elsif Gem::Dependency.new("rails", "~> 7.0").match?("rails", Gem.loaded_specs["rails"].version)
          { env_name: Rails.env, name: specification_name }
        end
      end

      before do
        @original_config_spec_name = DataMigrate.config.spec_name

        DataMigrate.configure do |config|
          config.spec_name = specification_name
        end

        allow(ActiveRecord::Base.configurations)
          .to receive(:configs_for)
          .with(config_options)
          .and_return(config)
        allow(config).to receive(:migrations_paths).and_return(paths)
      end

      after do
        DataMigrate.configure do |config|
          config.spec_name = @original_config_spec_name
        end
      end

      it 'lists schema migration paths' do
        expect(subject.migrations_paths.size).to eq(paths.count)
        expect(subject.migrations_paths).to eq(paths)
      end
    end
  end
end
