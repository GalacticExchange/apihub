
namespace :mysync do
  task :commit_server_shared do
    on roles(:app) do
      execute "cd #{shared_path} && git add -A . && git commit -m \"server changes \" " rescue true
      execute "cd #{shared_path} && git push origin production-shared " rescue true
    end
  end

  task :update_server_shared do
    on roles(:app) do
      execute "cd #{shared_path} && git pull origin production-shared " rescue true
    end
  end

end
