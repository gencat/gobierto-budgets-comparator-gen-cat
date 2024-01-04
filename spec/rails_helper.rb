ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'email_spec'
require 'rack/test'
require "database_cleaner"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.args << "--headless"
  options.args << "--no-sandbox"
  options.args << "--window-size=1920,1080"

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!

  config.include(Factories)
  config.include(Paths)
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
  config.include ActiveSupport::Testing::TimeHelpers

  Capybara.javascript_driver = :headless_chrome
  Capybara.default_max_wait_time = 5
  Capybara.server_port = 31337

  config.before(:suite) do
    %x[bundle exec rake assets:precompile]

    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:transaction)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.after(:each) do
    travel_back
    reset_mailer
  end
end
