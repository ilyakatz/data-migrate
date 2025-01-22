# frozen_string_literal: true

module DataMigrate
  module Tasks
    class SetupTests
      INJECTION_MATCHER = Regexp.new(/require_relative ["|']\.\.\/config\/environment["|']/)

      def call
        return if injection_exists?

        if find_injection_location.nil?
          puts 'data_migrate: config/environment.rb was not found in the test helper file.'
          return
        end

        add_newline

        lines_for_injection.reverse.each do |line|
          file_contents.insert(find_injection_location, "#{line}\n")
        end

        add_newline

        File.open(test_helper_file_path, 'w') do |file|
          file.puts file_contents
        end

        puts 'data_migrate: Test setup complete.'
      end

      private

      def test_helper_file_path
        case DataMigrate::Helpers::InferTestSuiteType.new.call
        when :rspec
          Rails.root.join('spec', 'rails_helper.rb')
        when :minitest
          Rails.root.join('test', 'test_helper.rb')
        end
      end

      def file_contents
        @_file_contents ||= File.readlines(test_helper_file_path)
      end

      def find_injection_location
        @_find_injection_location ||= begin
          index = file_contents.index { |line| line.match?(INJECTION_MATCHER) }
          index.present? ? index + 1 : nil
        end
      end

      def add_newline
        file_contents.insert(find_injection_location, "\n")
      end

      def lines_for_injection
        [
          "# data_migrate: Include data migrations for writing test coverage",
          "Dir[Rails.root.join(DataMigrate.config.data_migrations_path, '*.rb')].each { |f| require f }"
        ]
      end

      def injection_exists?
        file_contents.each_cons(lines_for_injection.length) do |content_window|
          if content_window.map(&:strip) == lines_for_injection.map(&:strip)
            puts 'data_migrate: Test setup already exists.'
            return true
          end
        end

        false
      end
    end
  end
end
