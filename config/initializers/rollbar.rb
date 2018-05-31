require 'rollbar/rails'

Rollbar.configure do |config|
  config.access_token = Rails.application.secrets.rollbar_access_token
  config.exception_level_filters.merge!({
    'ActionController::InvalidCrossOriginRequest' => 'ignore',
    'ActionController::RoutingError' => 'ignore',
    'ActionController::UnknownFormat' => 'ignore'
  })
end
