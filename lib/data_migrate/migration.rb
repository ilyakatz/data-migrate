module DataMigrate
  class Migration < ::ActiveRecord::Migration[5.0]

    class << self
      def check_pending!(connection = ::ActiveRecord::Base.connection)
        raise ActiveRecord::PendingMigrationError if DataMigrator::Migrator.needs_migration?(connection)
      end

      def migrate(direction)
        new.migrate direction
      end

      def table_name
        ActiveRecord::Base.table_name_prefix + 'data_migrations' + ActiveRecord::Base.table_name_suffix
      end

      def index_name
        "#{table_name_prefix}unique_data_migrations#{table_name_suffix}"
      end
    end

    def initialize(name = self.class.name, version = nil)
      super(name, version)
    end
  end
end
