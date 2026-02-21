class TwoFactorSessionsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.minute, only: :create, with: -> { redirect_to new_two_factor_session_path, alert: "Too many attempts. Try again later." }

  before_action :ensure_pending_user

  def new
  end

  def create
    if @user.verify_otp(params[:otp_code])
      session.delete(:pending_user_id)
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      flash.now[:alert] = "Invalid code. Please try again."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def ensure_pending_user
    @user = User.find_by(id: session[:pending_user_id])
    unless @user&.otp_required?
      redirect_to new_session_path, alert: "Please log in first."
    end
  end
end
