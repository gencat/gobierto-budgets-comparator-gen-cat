require File.expand_path('../config/application', __FILE__)

# Load Gobierto data tasks
spec = Gem::Specification.find_by_name 'gobierto_data'
load "#{spec.gem_dir}/lib/tasks/data.rake"

Rails.application.load_tasks
