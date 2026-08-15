class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: t("flash.passwords.create.rate_limit") }

  def new
  end

  def create
    PasswordsMailer.with(email_address: params[:email_address]).reset.deliver_later

    redirect_to new_session_path, notice: t("flash.passwords.create.notice")
  end

  def edit
    @user.with_lock do
      @user = User.find_by_password_reset_token!(params[:token])
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: t("flash.passwords.invalid_token")
  end

  def update
    updated = @user.with_lock do
      user = User.find_by_password_reset_token!(params[:token])
      if user.update(params.permit(:password, :password_confirmation))
        user.sessions.destroy_all
        true
      else
        false
      end
    end

    if updated
      redirect_to new_session_path, notice: t("flash.passwords.update.notice")
    else
      redirect_to edit_password_path(params[:token]), alert: t("flash.passwords.update.alert")
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: t("flash.passwords.invalid_token")
  end
end
