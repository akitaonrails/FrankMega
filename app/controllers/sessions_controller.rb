class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("flash.sessions.create.rate_limit") }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))

    if user.nil?
      redirect_to new_session_path, alert: t("flash.sessions.create.invalid_credentials")
      return
    end

    if user.banned?
      redirect_to new_session_path, alert: t("flash.sessions.create.account_suspended")
      return
    end

    if user.otp_required?
      # Reset session to prevent fixation, then store pending user
      reset_session
      session[:pending_user_id] = user.id
      redirect_to new_two_factor_session_path
      return
    end

    start_new_session_for user
    redirect_to after_authentication_url
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
