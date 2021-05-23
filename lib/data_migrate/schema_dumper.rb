# frozen_string_literal: true

module DataMigrate
  ##
  # Provides the capability to write the current data schema version to
  # the data_schema file Based on ActiveRecord::SchemaDumper
  class SchemaDumper
    private_class_method :new

    class << self
      def dump(connection = ActiveRecord::Base.connection, stream = STDOUT)
        new(connection).dump(stream)
        stream
      end
    end

    def dump(stream)
      define_params = @version ? "version: #{@version}" : ""

      stream.puts "DataMigrate::Data.define(#{define_params})"

      stream
    end

    private

    def initialize(connection)
      @connection = connection
      all_versions =  DataSchemaMigration.normalized_versions

      @version = begin
                    all_versions.max
                  rescue StandardError
                    0
                  end
    end
  end
end
