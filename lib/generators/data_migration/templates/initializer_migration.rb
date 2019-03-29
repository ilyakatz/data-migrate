class <%= 'CreateDataMigrations' %> < <%= migration_base_class_name %>
  def up
    create_table :data_migrations, primary_key: "version", id: :string do |t|
    end
  end

  def down
    drop_table :data_migrations
  end
end
