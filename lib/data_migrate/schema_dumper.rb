module DataMigrate
  ##
  # Provides the capability to write the current data schema version to the data_schema file
  # Based on ActiveRecord::SchemaDumper
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

      if stream.respond_to?(:external_encoding) && stream.external_encoding
        stream.puts "# encoding: #{stream.external_encoding.name}"
      end

      stream.puts "DataMigrate::Data.define(#{define_params})"

      stream
    end

    private

      def initialize(connection)
        @connection = connection
        @version = DataMigrate::DataSchemaMigration.all.map { |x| x.version.to_i }.max rescue 0
      end
  end
end
