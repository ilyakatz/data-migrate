namespace :deploy do

  desc 'Runs rake data:migrate if migrations are set'
  Rake::Task['deploy:migrate'].clear_actions
  task :migrate => [:set_rails_env] do
    on fetch(:migration_servers) do
      conditionally_migrate = fetch(:conditionally_migrate)
      info '[deploy:migrate] Checking changes in db/migrate or db/data' if conditionally_migrate

      if conditionally_migrate &&
         test("diff -q #{release_path}/db/migrate #{current_path}/db/migrate") &&
         test("diff -q #{release_path}/db/data #{current_path}/db/data")
        info '[deploy:migrate] Skip `deploy:migrate` (nothing changed in db/migrate or db/data)'
      else
        info '[deploy:migrate] Run `rake db:migrate:with_data`'
        invoke :'deploy:migrating_with_data'
      end
    end
  end

  desc 'Runs rake db:migrate:with_data'
  task migrating_with_data: [:set_rails_env] do
    on fetch(:migration_servers) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:migrate:with_data'
        end
      end
    end
  end

  after 'deploy:updated', 'deploy:migrate'
end

namespace :load do
  task :defaults do
    set :conditionally_migrate, fetch(:conditionally_migrate, false)
    set :migration_role, fetch(:migration_role, :db)
    set :migration_servers, -> { primary(fetch(:migration_role)) }
  end
end
