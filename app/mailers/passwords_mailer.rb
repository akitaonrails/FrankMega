class PasswordsMailer < ApplicationMailer
  def reset
    @user = User.find_by(email_address: params[:email_address])
    return unless @user

    mail subject: t("passwords_mailer.reset.subject"), to: @user.email_address
  end
end
