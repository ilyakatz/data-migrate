# frozen_string_literal: true

module DataMigrate
  ##
  # Provides the capability to write the current data schema version to
  # the data_schema file Based on ActiveRecord::SchemaDumper
  class SchemaDumper
    private_class_method :new

    class << self
      def dump(connection = ActiveRecord::Base.connection, stream = $stdout)
        new(connection).dump(stream)
        stream
      end
    end

    def dump(stream)
      define_params = @version ? "version: #{formatted_version}" : ""

      stream.puts "DataMigrate::Data.define(#{define_params})"

      stream
    end

    private

    def initialize(connection)
      @connection = connection
      all_versions =  DataMigrate::RailsHelper.data_schema_migration.normalized_versions

      @version = begin
                    all_versions.max
                  rescue StandardError
                    0
                  end
    end

    # turns 20170404131909 into "2017_04_04_131909"
    def formatted_version
      stringified = @version.to_s
      return stringified unless stringified.length == 14
      stringified.insert(4, "_").insert(7, "_").insert(10, "_")
    end
  end
end
