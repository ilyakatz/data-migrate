module DataMigrate
  module Helpers
    class InferTestSuiteType
      def call
        return DataMigrate.config.test_framework if DataMigrate.config.test_framework.present?

        if File.exist?(Rails.root.join('spec', 'spec_helper.rb'))
          :rspec
        elsif File.exist?(Rails.root.join('test', 'test_helper.rb'))
          :minitest
        else
          raise StandardError.new('Unable to determine test suite')
        end
      end
    end
  end
end
