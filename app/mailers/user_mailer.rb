class UserMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    mail to: @user.email, subject: 'Nueva contraseña'
  end

  def verification_notification(user)
    @user = user
    mail to: @user.email, subject: 'Completa tu cuenta'
  end
end
