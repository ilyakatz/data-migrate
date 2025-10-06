module DataMigrate
  module Helpers
    class InferTestFramework
      def call
        if File.exist?(File.expand_path('spec/spec_helper.rb'))
          :rspec
        elsif File.exist?(File.expand_path('test/test_helper.rb'))
          :minitest
        else
          raise StandardError.new('Unable to determine test suite')
        end
      end
    end
  end
end
