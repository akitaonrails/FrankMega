class TwoFactorSessionsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.minute, name: "ip", store: Rack::Attack.cache.store, only: :create,
             with: -> { redirect_to new_two_factor_session_path, alert: t("flash.two_factor_sessions.create.rate_limit") }
  rate_limit to: 5, within: 5.minutes, name: "pending-user", store: Rack::Attack.cache.store,
             by: -> { session[:pending_user_id] || "missing:#{request.remote_ip}" }, only: :create,
             with: -> { redirect_to new_two_factor_session_path, alert: t("flash.two_factor_sessions.create.rate_limit") }

  before_action :ensure_pending_user

  def new
  end

  def create
    if @user.verify_otp(params[:otp_code]) && !@user.banned?
      clear_pending_challenge
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      flash.now[:alert] = t("flash.two_factor_sessions.create.alert")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def ensure_pending_user
    @user = User.find_by(id: session[:pending_user_id])
    challenge_expired = session[:pending_challenge_at].to_i < 5.minutes.ago.to_i
    salt_matches = @user&.password_salt == session[:pending_password_salt]
    unless @user&.otp_required? && !@user.banned? && !challenge_expired && salt_matches
      clear_pending_challenge
      redirect_to new_session_path, alert: t("flash.two_factor_sessions.login_required")
    end
  end

  def clear_pending_challenge
    session.delete(:pending_user_id)
    session.delete(:pending_challenge_at)
    session.delete(:pending_password_salt)
  end
end
