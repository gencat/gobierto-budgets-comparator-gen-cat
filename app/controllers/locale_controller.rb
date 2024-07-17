class LocaleController < ApplicationController
  def update
    if params[:locale].present?
      new_locale = params[:locale].to_sym
      if I18n.available_locales.include?(new_locale)
        session[:locale] = new_locale
      end
    end

    if request.referrer === set_locale_url(locale: params[:locale])
      redirect_to root_path
    else
      redirect_back(fallback_location: location_root_path)
    end
  end
end
