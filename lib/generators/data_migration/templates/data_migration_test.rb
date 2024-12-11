require 'test_helper'

class <%= migration_class_name %>Test < ActiveSupport::TestCase
  def setup
    @migration = <%= migration_class_name %>.new
  end

  def test_migration_up
    skip("Pending test coverage for @migration.up")
  end

  def test_migration_down
    skip("Pending test coverage for @migration.down")
  end
end
