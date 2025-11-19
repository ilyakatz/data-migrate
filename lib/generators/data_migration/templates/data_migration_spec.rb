require 'rails_helper'
require './<%= data_migrations_file_path_with_version %>'

describe <%= migration_class_name %>, type: :data_migration do
  let(:migration) { <%= migration_class_name %>.new }

  pending "should test `migration.up`"

  pending "should test `migration.down`"
end
