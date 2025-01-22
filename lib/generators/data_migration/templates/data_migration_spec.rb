require 'rails_helper'

describe <%= migration_class_name %>, type: :data_migration do
  let(:migration) { <%= migration_class_name %>.new }

  pending "should test `migration.up`"

  pending "should test `migration.down`"
end
