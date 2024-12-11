# frozen_string_literal: true

require "spec_helper"

describe DataMigrate::Tasks::SetupTests do
  let(:file_contents_with_injection) do
    <<~FILE_CONTENTS
      # This file is copied to spec/ when you run 'rails generate rspec:install'
      require 'spec_helper'
      ENV['RAILS_ENV'] ||= 'test'
      require_relative '../config/environment'

      # data_migrate: Include data migrations for writing test coverage
      Dir[Rails.root.join(DataMigrate.config.data_migrations_path, '*.rb')].each { |f| require f }
    FILE_CONTENTS
  end
  let(:file_contents_without_injection) do
    <<~FILE_CONTENTS
      # This file is copied to spec/ when you run 'rails generate rspec:install'
      require 'spec_helper'
      ENV['RAILS_ENV'] ||= 'test'
      require_relative '../config/environment'
    FILE_CONTENTS
  end
  let(:file_contents_without_injection_matcher) do
    <<~FILE_CONTENTS
      # This file is copied to spec/ when you run 'rails generate rspec:install'
      require 'spec_helper'
      ENV['RAILS_ENV'] ||= 'test'
    FILE_CONTENTS
  end
  let(:rails_root) { Pathname.new('/fake/app') }
  let(:test_suite_inferrer) { instance_double(DataMigrate::Helpers::InferTestSuiteType) }

  before do
    allow(Rails).to receive(:root).and_return(rails_root)
    allow(DataMigrate::Helpers::InferTestSuiteType).to receive(:new).and_return(test_suite_inferrer)
  end

  describe "#call" do
    context 'when the injected code already exists' do
      it 'returns early' do
        allow(test_suite_inferrer).to receive(:call).and_return(:rspec)
        allow(File).to receive(:readlines).and_return(file_contents_with_injection.lines)

        expect(File).not_to receive(:open)

        expect {
          DataMigrate::Tasks::SetupTests.new.call
        }.to output(/data_migrate: Test setup already exists./).to_stdout
      end

      context 'when the INJECTION_MATCHER is not found' do
        it 'returns early' do
          allow(test_suite_inferrer).to receive(:call).and_return(:rspec)
          allow(File).to receive(:readlines).and_return(file_contents_without_injection_matcher.lines)

          expect(File).not_to receive(:open)

          expect {
            DataMigrate::Tasks::SetupTests.new.call
          }.to output(/data_migrate: config\/environment.rb was not found in the test helper file./).to_stdout
        end
      end

      context 'for RSpec' do
        it 'calls File.open for writing to rails_helper.rb' do
          allow(test_suite_inferrer).to receive(:call).and_return(:rspec)
          allow(File).to receive(:readlines).and_return(file_contents_without_injection.lines)

          expect(File).to receive(:open).with(rails_root.join('spec', 'rails_helper.rb'), 'w')

          expect {
            DataMigrate::Tasks::SetupTests.new.call
          }.to output(/data_migrate: Test setup complete./).to_stdout
        end
      end

      context 'for Minitest' do
        it 'calls File.open for writing to test_helper.rb' do
          allow(test_suite_inferrer).to receive(:call).and_return(:minitest)
          allow(File).to receive(:readlines).and_return(file_contents_without_injection.lines)

          expect(File).to receive(:open).with(rails_root.join('test', 'test_helper.rb'), 'w')

          expect {
            DataMigrate::Tasks::SetupTests.new.call
          }.to output(/data_migrate: Test setup complete./).to_stdout
        end
      end
    end
  end
end
