lock '3.5.0'

def deploy_var(key)
  @deploy_secrets_yml ||= YAML.load_file('config/deploy_secrets.yml')[fetch(:stage).to_s]
  @deploy_secrets_yml.fetch(key.to_s, 'undefined')
end

set :rails_env, fetch(:stage)
set :application, deploy_var(:application)
set :repo_url, deploy_var(:repo_url)
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml', "config/settings/#{fetch(:stage)}.yml")
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/cache')
set :rbenv_type, :user
set :rbenv_ruby, '2.3.1'
set :rbenv_path, '/home/ubuntu/.rbenv'
set :passenger_restart_with_touch, true
