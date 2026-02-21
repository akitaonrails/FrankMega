class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: t("passwords_mailer.reset.subject"), to: user.email_address
  end
end
