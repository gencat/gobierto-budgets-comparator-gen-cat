set :application, 'gobierto-budgets-comparator-staging'
server 'staging01', user: 'ubuntu', roles: %w{app db web}
set :branch, 'master'
set :rails_env, 'staging'
