# frozen_string_literal: true

module DataMigrate
  ##
  # This class extends DatabaseTasks to add a data_schema_file method.
  class DatabaseTasks
    extend ActiveRecord::Tasks::DatabaseTasks

    def self.data_schema_file
      File.join(db_dir, "data_schema.rb")
    end
  end
end
