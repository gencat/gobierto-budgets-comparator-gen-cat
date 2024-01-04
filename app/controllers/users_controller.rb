class UsersController < ApplicationController
  layout 'gobierto_budgets_application'

  before_action :check_users_enabled
  before_action :load_current_user, only: [:edit, :update]

  def new
    redirect_to edit_user_path if logged_in?

    @user = User.new(params.permit(:place_id, :pro))
    @place_id = params[:place_id]
  end

  def create
    @user = User.new create_user_params
    if @user.save
      redirect_to root_path, notice: 'Por favor, confirma tu email'
    else
      render 'new'
    end
  end

  def identify
    @user = User.find_or_initialize_by email: params[:user][:email]
    if @user.new_record?
      @user.attributes = create_user_params
      if @user.save
        created = true
      else
        render 'new' and return
      end
    end
    session[:follow] = params[:follow] if params[:follow]

    respond_to do |format|
      format.html do
        if created
          redirect_to root_path, notice: 'Por favor, confirma tu email'
        else
          redirect_back fallback_location: root_path
        end
      end
      format.js do
        @form_context = params[:context]
        (created || @user.pending_confirmation?) ? render('created') : render('login')
      end
    end
  end

  def verify
    @user = User.find_by! verification_token: params[:id]
    log_in(@user)
  end

  def edit
  end

  def update
    if @user.update(update_user_params)
      if @user.pending_confirmation?
        @user.clear_verification_token
        @user.update_pending_answers(session.id)
        store_subscriptions
      end
      @user.save!
      redirect_to root_path, notice: 'Datos actualizados correctamente'
    else
      flash.now.alert = 'No se han podido actualizar los datos'
      render 'edit'
    end
  end

  private

  def create_user_params
    params.require(:user).permit(:first_name, :last_name, :email, :place_id, :pro, :terms_of_service)
  end

  def update_user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password, :place_id, :pro, :terms_of_service)
  end

  def load_current_user
    redirect_to login_path and return unless logged_in?

    @user = current_user
  end
end
