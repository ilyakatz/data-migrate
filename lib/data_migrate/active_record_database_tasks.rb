# frozen_string_literal: true

module DataMigrate
  ##
  # This class extends DatabaseTasks to add a schema_file method.
  module ActiveRecordDatabaseTasks
    extend ActiveRecord::Tasks::DatabaseTasks
    extend self

    if respond_to?(:db_configs_with_versions)
      if method(:db_configs_with_versions).arity == 1
        # In Rails 7.0 and 7.1, the with_temporary_connection_for_each method takes in an unused
        # argument. It has since been removed.
        # https://github.com/rails/rails/commit/9572fcb4a0bd5396436689a6a42613886871cd81
        def db_configs_with_versions
          super(nil)
        end
      end
    else
      # For Rails 6.x
      def db_configs_with_versions
        db_configs_with_versions = Hash.new { |h, k| h[k] = [] }

        with_temporary_pool_for_each do |pool|
          db_config = pool.db_config
          versions_to_run = pool.migration_context.pending_migration_versions
          target_version = ActiveRecord::Tasks::DatabaseTasks.target_version

          versions_to_run.each do |version|
            next if target_version && target_version != version
            db_configs_with_versions[version] << db_config
          end
        end

        db_configs_with_versions
      end

      unless respond_to?(:with_temporary_pool_for_each)
        def with_temporary_connection_for_each(env: ActiveRecord::Tasks::DatabaseTasks.env, name: nil, &block) # :nodoc:
          if name
            db_config = ActiveRecord::Base.configurations.configs_for(env_name: env, name: name)
            with_temporary_connection(db_config, &block)
          else
            ActiveRecord::Base.configurations.configs_for(env_name: env, name: name).each do |db_config|
              with_temporary_connection(db_config, &block)
            end
          end
        end

        def with_temporary_connection(db_config) # :nodoc:
          with_temporary_pool(db_config) do |pool|
            yield pool.connection
          end
        end
      end
    end
  end
end
