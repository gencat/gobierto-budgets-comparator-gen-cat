require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GobiertoBudgetsComparator
  class Application < Rails::Application
    config.i18n.default_locale = :es
    config.i18n.available_locales = [:es, :ca]

    config.generators do |g|
      g.test_framework  :rspec, fixtures: false, view_spec: false,
                                helper_specs: false, routing_specs: false,
                                controller_specs: false, request_specs: false
    end

    config.action_dispatch.default_headers.merge!({
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Request-Method" => "*"
    })

    config.action_mailer.default_url_options = { host: Settings.gobierto_host, protocol: "https" }

    # Autoloading
    required_paths = [
      "#{config.root}/lib",
      "#{config.root}/lib/validators"
    ]
    config.autoload_paths += required_paths
    config.eager_load_paths += required_paths

    # Load custom views from app/views/custom
    config.paths["app/views"].unshift(Rails.root.join("app", "views", "custom"))

    config.action_controller.permit_all_parameters = true

    config.action_controller.page_cache_directory = Rails.root.join("public", "cache")


    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end

require Rails.root.join("app", "models", "gobierto_budgets")
require Rails.root.join("app", "models", "gobierto_budgets", "search_engine_configuration")

require "./config/application_custom.rb"
