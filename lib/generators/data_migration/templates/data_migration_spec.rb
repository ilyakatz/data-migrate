require "rails_helper"
require Rails.root.join(%q{<%= data_migrations_load_path %>})

describe <%= migration_class_name %> do
  let(:migrator) {
    described_class.new.tap do |m|
      m.verbose = false
    end
  }

  describe "#up" do
    subject { migrator.migrate(:up) }

    pending "Needs tests"
  end

  describe "#down" do
    subject { migrator.migrate(:down) }

    pending "Needs tests"
  end
end