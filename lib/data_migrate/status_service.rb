module DataMigrate
  class StatusService
    class << self
      def dump(connection = ActiveRecord::Base.connection, stream = STDOUT)
        new(connection).dump(stream)
        stream
      end
    end

    def initialize(connection)
      @connection = connection
    end

    def root_folder
      Rails.root
    end

    def dump(stream)
      unless @connection.table_exists?(table_name)
        stream.puts "Data migrations table does not exist yet."
        return
      end
      sql = "SELECT version FROM #{DataMigrate::DataMigrator.schema_migrations_table_name}"
      db_list = ActiveRecord::Base.connection.select_values(sql)
      output(stream, db_list)
    end

    private

    def table_name
      DataMigrate::DataMigrator.schema_migrations_table_name
    end

    def output(stream, db_list)
      stream.puts "#{"Status".center(8)}  #{"Migration ID".ljust(14)}  Migration Name"
      stream.puts "-" * 50
      list =  migration_files(db_list) + migration_list(db_list)
      list.sort! {|line1, line2| line1[1] <=> line2[1]}
      list.each do |file|
        stream.puts "#{file[0].center(8)}  #{file[1].ljust(14)}  #{file[2]}"
      end
      stream.puts
    end

    def migration_list(db_list)
      list = []
      db_list.each do |version|
        list << ["up", version, "********** NO FILE *************"]
      end
      list
    end

    def migration_files(db_list)
      file_list = []
      Dir.foreach(File.join(root_folder, DataMigrate.config.data_migrations_path)) do |file|
        # only files matching "20091231235959_some_name.rb" pattern
        if match_data = DataMigrate::DataMigrator.match(file)
          status = db_list.delete(match_data[1]) ? "up" : "down"
          file_list << [status, match_data[1], match_data[2].humanize]
        end
      end
      file_list
    end
  end
end
