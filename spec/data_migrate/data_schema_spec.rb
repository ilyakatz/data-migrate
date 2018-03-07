# frozen_string_literal: true

describe DataMigrate::Data do
  let(:subject) { DataMigrate::Data }
  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end
  let(:fixture_file_timestamps) do
    %w[20091231235959 20101231235959 20111231235959]
  end

  around do |example|
    Dir.mktmpdir do |temp_dir|
      @temp_dir = temp_dir

      # create the fake data migration files
      fixture_file_timestamps.each do |timestamp|
        FileUtils.touch File.join(temp_dir, "#{timestamp}_data_migration.rb")
      end

      example.run
    end
  end

  describe :define do
    before do
      expect(DataMigrate::DataMigrator).
        to receive(:db_config) { db_config }.at_least(:once)
      ActiveRecord::Base.establish_connection(db_config)
      #ActiveRecord::Base.connection.initialize_schema_migrations_table
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
    end

    context "when no version is supplied" do
      it "returns nil" do
        expect(subject.define(version: nil)).to be_nil
      end
    end

    context "when a version is supplied" do
      before do
        allow(DataMigrate::DataMigrator).
          to receive(:full_migrations_path).and_return(@temp_dir)
      end

      it "sets the current version to the supplied version" do
        version = fixture_file_timestamps[1]

        expect(DataMigrate::DataMigrator.current_version).not_to eq version.to_i
        subject.define(version: version)
        expect(DataMigrate::DataMigrator.current_version).to eq version.to_i
      end

      it "creates entries for migration versions that come " \
         "before the supplied version" do

        version = fixture_file_timestamps[1]

        subject.define(version: version)

        sql_select = <<-SQL
          SELECT version
          FROM #{DataMigrate::DataMigrator.schema_migrations_table_name}
        SQL

        db_list_data = ActiveRecord::Base.connection.
          select_values(sql_select).map(&:to_i)
        expect(db_list_data).to match_array(
          [fixture_file_timestamps[0], fixture_file_timestamps[1]].map(&:to_i)
        )

        # The last remaining migration (fixture_file_timestamps[2]) was
        # not included as part of the supplied version and so should not
        # appear in the data_migrations table.
        expect(db_list_data).not_to include(fixture_file_timestamps[2])
      end
    end
  end
end
