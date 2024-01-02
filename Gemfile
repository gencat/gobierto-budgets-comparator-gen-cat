source 'https://rubygems.org'

gem "rails", "~> 6.1"
gem "pg", "~> 0.19"
gem 'sass-rails', '~> 5.0.0'
gem 'uglifier', '>= 1.3.0'
gem 'redcarpet', require: true
gem 'bcrypt'
gem 'rollbar'
gem 'meta-tags'
gem 'ine-places'
gem 'actionpack-action_caching'
gem "actionpack-page_caching"
gem 'ruby_px'
gem "kaminari", "~> 1.0"
gem 'responders'
gem 'config'
gem 'dalli'
gem "aws-ses", git: "https://github.com/zebitex/aws-ses.git", ref: "78-sigv4-problem"
gem 'cocoon'
gem 'nokogiri', '~> 1.14'
gem 'json', '~> 2.1'
gem "gobierto_budgets_data", git: "https://github.com/PopulateTools/gobierto_budgets_data.git"
gem "bootsnap"
gem 'sprockets', '~> 3.7.2'

# Socrata integration
gem 'soda-ruby', '~> 0.2.24', require: 'soda'

# Frontend
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem "bourbon", "~> 4.3.4"
gem 'turbolinks'
gem 'cookies_eu'
gem 'flight-for-rails'
gem "i18n-js", "~> 3.8.3"

# Webpack
gem "webpacker"

# Elastic search
gem 'elasticsearch'
gem 'elasticsearch-extensions'
gem 'oj'
gem 'hashie'

# Log
gem "lograge"

group :development, :test do
  gem "byebug", platform: :mri
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "rb-readline"
  gem "i18n-tasks"
end

group :test do
  gem 'database_cleaner'
  gem 'rspec-rails'
  gem 'capybara'
  gem 'launchy'
  gem 'email_spec'
  gem 'timecop'
  gem 'selenium-webdriver'
  gem 'rack-test', require: "rack/test"
end

group :development do
  gem 'puma'
  gem "rubocop"
end
