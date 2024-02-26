class ApplicationController < ActionController::Base
  include SessionsManagement

  protect_from_forgery with: :exception

  rescue_from ActionController::RoutingError, with: :render_404
  rescue_from ActionController::UnknownFormat, with: :render_404
  rescue_from Elasticsearch::Transport::Transport::Errors::BadRequest, with: :render_404

  helper_method :helpers, :users_enabled?, :places_collection_key

  before_action :set_locale, :set_cache_headers

  def render_404
    render file: Rails.root.join("public/404.html"), status: 404, layout: false, handlers: [:erb], formats: [:html]
  end

  def helpers
    ActionController::Base.helpers
  end

  def choose_layout
    response.headers.delete "X-Frame-Options"
    # response.headers["X-FRAME-OPTIONS"] = "ALLOW-FROM http://some-origin.com"
    return 'gobierto_budgets_embedded' if params[:e].present?
    return 'gobierto_budgets_application'
  end

  def default_url_options(options={})
    if params[:e].present?
      { e: true }
    else
      {}
    end
  end

  def set_locale
    I18n.locale = session[:locale] || I18n.default_locale
  rescue I18n::InvalidLocale
    session[:locale] = nil
    I18n.locale = I18n.default_locale
  end

  private

  def set_cache_headers
    response.headers["Cache-Control"] = "public,864000"
    response.headers["Expires"] = 10.days.from_now
  end

  protected

  def store_subscriptions
    if session[:follow]
      subscription = current_user.subscriptions.create place_id: session[:follow]
      @place = subscription.place
      session[:follow] = nil
    end
  end

  def remote_ip
    env['action_dispatch.remote_ip'].calculate_ip
  end

  def domain
    @domain ||= (env['HTTP_HOST'] || env['SERVER_NAME'] || env['SERVER_ADDR']).split(':').first
  end

  def check_users_enabled
    redirect_to root_path and return false unless users_enabled?
  end

  def users_enabled?
    Settings.users_enabled
  end

  def places_collection_key
    @places_collection_key ||= begin
                                 keys = PlaceDecorator.places_keys
                                 keys.include?(params[:places_collection]&.to_sym) ? params[:places_collection].to_sym : keys.first
                               end
  end
end
