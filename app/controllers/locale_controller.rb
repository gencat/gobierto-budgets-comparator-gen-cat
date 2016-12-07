class LocaleController < ApplicationController
  def update
    if params[:locale].present?
      new_locale = params[:locale].to_sym
      if I18n.available_locales.include?(new_locale)
        session[:locale] = new_locale
      end
    end
    redirect_to :back
  rescue ActionController::RedirectBackError
    redirect_to root_path
  end
end
