# frozen_string_literal: true

module DataMigrate
  ##
  # Provides the definition method for data_schema.rb
  class Data < ActiveRecord::Schema
    # This method is based on the following two methods
    #   ActiveRecord::Schema#define
    #   ActiveRecord::ConnectionAdapters::SchemaStatements
    #     #assume_migrated_upto_version
    def define(info)
      DataMigrate::DataMigrator.assure_data_schema_table

      return if info[:version].blank?

      version = info[:version].to_i

      unless migrated.include?(version)
        execute "INSERT INTO #{sm_table} (version) VALUES ('#{version}')"
      end

      insert(version)
    end

    private

    def migrated
      @migrated ||= select_values("SELECT version FROM #{sm_table}").map(&:to_i)
    end

    def versions
      @versions ||= begin
        versions = []
        Dir.foreach(DataMigrate::DataMigrator.full_migrations_path) do |file|
          match_data = DataMigrate::DataMigrator.match(file)
          versions << match_data[1].to_i if match_data
        end
        versions
      end
    end

    def insert(version)
      inserted = Set.new
      (versions - migrated).each do |v|
        if inserted.include?(v)
          raise "Duplicate data migration #{v}. Please renumber your data " \
            "migrations to resolve the conflict."
        elsif v < version
          execute "INSERT INTO #{sm_table} (version) VALUES ('#{v}')"
          inserted << v
        end
      end
    end

    def sm_table
      quote_table_name(table_name)
    end

    def table_name
      DataMigrate::DataSchemaMigration.table_name
    end
  end
end
