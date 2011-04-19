class CreateDataMigrations < ActiveRecord::Migration
  def self.up
    create_table :data_migrations do |t|
      t.string :version, :null => false
    end

    add_index :data_migrations, :version, :unique => true, :name => "<%= ActiveRecord::Base.table_name_prefix %>unique_data_migrations<%= ActiveRecord::Base.table_name_suffix %>"
  end

  def self.down
    drop_table :data_migrations
  end
end
