require "rake"

shared_context "rake" do
  let(:rake)      { Rake::Application.new }
  let(:task_name) { self.class.top_level_description }
  let(:task_path) { "/Users/katz/ws/data-migrate/tasks/databases" }
  subject         { rake[task_name] }

  def loaded_files_excluding_current_rake_file
    $".reject {|file| file =~ /#{task_path}.rake/}
  end

  before do
    Rake.application = rake
    binding.pry
    Rake.application.rake_require(task_path,  loaded_files_excluding_current_rake_file)
    task_path="/Users/katz/ws/data-migrate/tasks/databases"

    Rake::Task.define_task(:environment)
  end
end
