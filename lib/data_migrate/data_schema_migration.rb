module DataMigrate
  class DataSchemaMigration < ActiveRecord::SchemaMigration
    # In Rails 7.1+, ActiveRecord::SchemaMigration methods are instance methods
    # So we only load the appropriate methods depending on Rails version.
    if DataMigrate::RailsHelper.rails_version_equal_to_or_higher_than_7_1
      def table_name
        ActiveRecord::Base.table_name_prefix + 'data_migrations' + ActiveRecord::Base.table_name_suffix
      end

      def primary_key
        "version"
      end
    else
      class << self
        def table_name
          ActiveRecord::Base.table_name_prefix + 'data_migrations' + ActiveRecord::Base.table_name_suffix
        end

        def primary_key
          "version"
        end

        def create_version(version)
          # Note that SchemaMigration.create_version in Rails 7.1 does not
          # raise an error if validations fail but we retain this behaviour for now.
          create!(version: version)
        end
      end
    end
  end
end
