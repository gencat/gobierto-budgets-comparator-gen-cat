module SessionsManagement
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?, :current_user?, :impersonated_session?, :current_user_admin?
  end

  def logged_in?
    !!current_user
  end

  def current_user
    @current_user ||= if (user_id = session[:user_id])
      User.find_by(id: user_id)
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user
        user
      end
    end
  end

  def current_user?(user)
    logged_in? && user == current_user
  end

  def logged_in_user
    unless logged_in?
      redirect_to login_path and return false
    end
  end

  def admin_user
    unless logged_in?
      session[:referer] = request.fullpath
      redirect_to login_path and return false
    end

    unless current_user.admin?
      flash[:alert] = t('controllers.sessions_management.admin_user.alert')
      redirect_to location_root_path and return false
    end
  end

  def current_user_admin?
    logged_in? && current_user.admin?
  end

  def impersonated_session?
    session[:admin_id].present?
  end

  private

  def log_in(user)
    session[:user_id] = user.id
    # By default remember the user
    remember(user)
  end

  def log_out
    forget(current_user)
    reset_session
    @current_user = nil
  end

  def log_out_impersonated
    admin = User.find(session[:admin_id])
    log_in(admin)
    session[:admin_id] = nil
  end

  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  def store_admin_session
    session[:admin_id] = current_user.id
  end
end
