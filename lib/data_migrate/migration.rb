module DataMigrate
  class Migration < ::ActiveRecord::Migration

    class << self
      def check_pending!(connection = ::ActiveRecord::Base.connection)
        raise ActiveRecord::PendingMigrationError if DataMigrator::Migrator.needs_migration?(connection)
      end

      def migrate(direction)
        new.migrate direction
      end

      def table_name
        ActiveRecord::Base.table_name_prefix + "data_migrations" + ActiveRecord::Base.table_name_suffix
      end

      def primary_key
        "version"
      end
    end

    def initialize(name = self.class.name, version = nil)
      super(name, version)
    end
  end
end
