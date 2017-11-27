module DataMigrate
  ##
  # This class extends DatabaseTasks to override the schema_file method.
  class DatabaseTasks
    extend ActiveRecord::Tasks::DatabaseTasks

    def self.schema_file(format = ActiveRecord::Base.schema_format)
      case format
      when :ruby
        File.join(db_dir, "data_schema.rb")
      else
        message = "Only Ruby-based data_schema files are supported at this time."
        Kernel.abort message
      end
    end
  end
end
