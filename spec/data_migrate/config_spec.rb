require "spec_helper"

describe DataMigrate::Config do

  it "sets default data_migrations_path path", :no_override do
    expect(DataMigrate.config.data_migrations_path).to eq "db/data/"
  end

  describe "data migration path configured" do
    before do
      @before = DataMigrate.config.data_migrations_path
      DataMigrate.configure do |config|
        config.data_migrations_path = "db/awesome/"
      end
    end

    after do
      DataMigrate.configure do |config|
        config.data_migrations_path = @before
      end
    end

    it do
      expect(DataMigrate.config.data_migrations_path).to eq "db/awesome/"
    end
  end
end
