require 'rollbar/rails'

Rollbar.configure do |config|
  config.access_token = Rails.application.credentials.rollbar_access_token
  config.enabled = Rails.env.production? || Rails.env.staging?
  config.exception_level_filters.merge!({
    'ActionController::InvalidCrossOriginRequest' => 'ignore',
    'ActionController::RoutingError' => 'ignore',
    'ActionController::UnknownFormat' => 'ignore'
  })
end
