class PasswordResetsController < ApplicationController
  layout 'gobierto_budgets_application'

  before_action :check_users_enabled
  before_action :load_user, only: [:edit, :update]

  def new
  end

  def create
    if user = User.find_by_email(params[:email])
      user.generate_password_reset_token!
      UserMailer.password_reset(user).deliver_now

      redirect_to root_path, notice: 'Te hemos enviado por e-mail instrucciones para recuperar tu contraseña'
    else
      flash.now[:alert] = 'E-mail no es válido'
      render 'new'
    end
  end

  def edit
    if @user.nil?
      flash.now[:alert] = 'Parece que el enlace que has pinchado es inválido'
      render 'new'
    end
  end

  def update
    if @user.update(user_params)
      @user.update_column :password_reset_token, nil
      log_in @user
      redirect_to edit_user_path, notice: 'Contraseña actualizada correctamente'
    else
      flash.now[:alert] = "La contraseña no pudo ser actualizada por los siguientes errores #{@user.errors.full_messages.to_sentence}"
      render 'edit'
    end
  end

  private

  def load_user
    @user = User.find_by_password_reset_token(params[:id])
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

end
