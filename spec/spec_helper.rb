require 'rspec'
require 'rails'
require 'data_migrate'
require 'pry'
require 'timecop'

Dir["./spec/support/**/*.rb"].each { |f| require f }
