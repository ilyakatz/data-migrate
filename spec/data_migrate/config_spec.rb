require "spec_helper"

describe DataMigrate::Config do

  it "sets default data_migrations_path path" do
    expect(DataMigrate.config.data_migrations_path).to eq "db/data/"
  end

  describe "data migration path configured" do
    before do
      DataMigrate.configure do |config|
        config.data_migrations_path = "db/awesome/"
      end
    end

    after do
      DataMigrate.configure do |config|
        config.data_migrations_path = "db/data/"
      end
    end

    it do
      expect(DataMigrate.config.data_migrations_path).to eq "db/awesome/"
    end
  end
end
