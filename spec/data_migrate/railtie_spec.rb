# frozen_string_literal: true

require "spec_helper"
require "json"
require "open3"
require "tmpdir"

describe DataMigrate::Railtie do
  let(:boot_path) { File.expand_path("../fixtures/check_pending_app/boot.rb", __dir__) }
  let(:lib_path) { File.expand_path("../../lib", __dir__) }

  def boot_app(pending_migration_error: nil)
    Dir.mktmpdir do |dir|
      env = {
        "RAILS_ENV" => "development",
        "DB_PATH" => File.join(dir, "development.sqlite3"),
        "PENDING_MIGRATION_ERROR" => pending_migration_error
      }
      output, status = Open3.capture2e(env, RbConfig.ruby, "-rbundler/setup", "-I", lib_path, boot_path)
      raise "Booting the app failed:\n#{output}" unless status.success?

      JSON.parse(output.lines.last)
    end
  end

  context "when pending_migration_error is not set" do
    subject(:result) { boot_app }

    it "serves the request even though data migrations are pending" do
      expect(result["status"]).to eq(200)
    end

    it "does not change the order in which initializers run" do
      expect(result["initializers"]).to eq(["later gem", "app config/initializers"])
    end
  end

  context "when pending_migration_error is :page_load in an initializer" do
    subject(:result) { boot_app(pending_migration_error: "page_load") }

    it "adds the middleware after Rails' pending schema migrations check" do
      middleware = result["middleware"]

      expect(middleware).to include("DataMigrate::CheckPending")
      expect(middleware.index("DataMigrate::CheckPending"))
        .to be > middleware.index("ActiveRecord::Migration::CheckPending")
    end

    it "renders the pending data migrations error with its action" do
      expect(result["status"]).to eq(500)
      expect(result["body"]).to include("DataMigrate::PendingMigrationError")
      expect(result["body"]).to include("20091231235959 SomeName")
      expect(result["body"]).to include("Run pending data migrations")
    end
  end
end
