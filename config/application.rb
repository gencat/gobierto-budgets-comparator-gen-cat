require File.expand_path('../boot', __FILE__)

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
require "ostruct"
require "pp"
require "digest"

Bundler.require(*Rails.groups)

module GobiertoBudgetsComparator
  class Application < Rails::Application
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :es
    config.i18n.available_locales = [:es, :en, :ca]

    config.active_record.raise_in_transactional_callbacks = true

    config.generators do |g|
      g.orm             :active_record
      g.template_engine :erb
      g.test_framework  :rspec, fixtures: false, view_spec: false,
                                helper_specs: false, routing_specs: false,
                                controller_specs: false, request_specs: false
    end

    config.action_dispatch.default_headers.merge!({
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Request-Method' => '*'
    })

    config.action_mailer.default_url_options = { host: Settings.gobierto_host, protocol: 'https' }

    # Autoloading
    config.autoload_paths += [
      "#{config.root}/lib",
      "#{config.root}/lib/validators"
    ]

    # Load custom views from app/views/custom
    config.paths['app/views'].unshift(Rails.root.join('app', 'views', 'custom'))
  end
end

require Rails.root.join('app', 'models', 'gobierto_budgets')
require Rails.root.join('app', 'models', 'gobierto_budgets', 'search_engine_configuration')

require "./config/application_custom.rb"
