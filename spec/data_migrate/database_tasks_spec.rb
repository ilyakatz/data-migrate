# frozen_string_literal: true

describe DataMigrate::DatabaseTasks do
  let(:subject) { DataMigrate::DatabaseTasks }

  before do
    # In a normal Rails installation, db_dir would defer to
    # Rails.application.config.paths["db"].first
    # @see https://github.com/rails/rails/blob/a7d49ef78c36df2d1ca876451f30915ada1079a5/activerecord/lib/active_record/tasks/database_tasks.rb#L54
    allow(subject).to receive(:db_dir).and_return("db")
  end

  describe :schema_file do
    it "returns the correct data schema file path" do
      expect(subject.schema_file).to eq "db/data_schema.rb"
    end
  end
end
