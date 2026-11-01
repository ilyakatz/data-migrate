# frozen_string_literal: true

require "json"
require "logger"
require "rails"
require "action_controller/railtie"
require "active_record/railtie"

INITIALIZERS = []

require "data_migrate"

class LaterGemRailtie < Rails::Railtie
  initializer("later_gem.setup") { INITIALIZERS << "later gem" }
end

ENV["DATABASE_URL"] = "sqlite3:#{ENV.fetch('DB_PATH')}"

class CheckPendingApp < Rails::Application
  config.root = __dir__
  config.eager_load = false
  config.logger = Logger.new(nil)
  config.secret_key_base = "secret"
  config.hosts.clear
  config.consider_all_requests_local = true
  config.active_record.migration_error = :page_load
end

Rails.application.initialize!
Rails.application.routes.draw do
  root to: proc { [200, {}, ["ok"]] }
end

status, _headers, body = Rails.application.call(Rack::MockRequest.env_for("/"))
response_body = +""
body.each { |part| response_body << part }

puts JSON.generate(
  initializers: INITIALIZERS,
  middleware: Rails.application.middleware.map(&:name),
  status: status,
  body: response_body
)
