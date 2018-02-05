# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::StatusService do
  let(:subject) { DataMigrate::SchemaDumper }
  let(:db_config) do
    {
      adapter: "sqlite3",
      database: "spec/db/test.db"
    }
  end
  let(:service) { DataMigrate::StatusService }

  describe :dump do
    before do
      ActiveRecord::Base.establish_connection(db_config)
    end

    describe "table does not exist" do
      it "table doesn't exist" do
        expect_any_instance_of(service).to receive(:table_name) { "bogus"}
        stream = StringIO.new
        service.dump(ActiveRecord::Base.connection, stream)
        stream.rewind

        expected = "Data migrations table does not exist"
        expect(stream.read).to include expected
      end
    end
  end

  describe :dump do
    context "table exists"
    let(:fixture_file_timestamps) do
      %w[20091231235959 20101231235959 20111231235959]
    end

    before do
      expect(DataMigrate::DataMigrator).
        to receive(:db_config) { db_config }.at_least(:once)
      ActiveRecord::Base.establish_connection(db_config)

      ActiveRecord::Base.connection.initialize_schema_migrations_table
      DataMigrate::DataMigrator.assure_data_schema_table

      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO #{DataMigrate::DataMigrator.schema_migrations_table_name}
        VALUES #{fixture_file_timestamps.map { |t| "(#{t})" }.join(', ')}
      SQL

      expect_any_instance_of(service).to receive(:root_folder) { "spec" }
    end

    after do
      ActiveRecord::Migration.drop_table("data_migrations")
    end

    it "shows successfully executed migration" do
      stream = StringIO.new
      service.dump(ActiveRecord::Base.connection, stream)
      stream.rewind

      expected = "   up     20091231235959  Some name"
      expect(stream.read).to include expected
    end

    it "shows missing file migration" do
      stream = StringIO.new
      service.dump(ActiveRecord::Base.connection, stream)
      stream.rewind

      expected = "   up     20101231235959  *** NO FILE ***"
      s = stream.read
      expect(s).to include expected
    end

    it "shows migration that has not run yet" do
      stream = StringIO.new
      service.dump(ActiveRecord::Base.connection, stream)
      stream.rewind

      expected = "  down    20171231235959  Super update"
      s = stream.read
      expect(s).to include expected
    end

    it "outputs migrations in chronological order" do
      stream = StringIO.new
      service.dump(ActiveRecord::Base.connection, stream)
      stream.rewind
      s = stream.read
      expect(s.index("20091231235959")).to be < s.index("20111231235959")
    end
  end
end
