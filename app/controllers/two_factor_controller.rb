class TwoFactorController < ApplicationController
  before_action :set_user

  def new
    if @user.otp_required? || !recent_two_factor_step_up?
      redirect_to profile_path
    else
      @user.generate_otp_secret!
      @qr_code = generate_qr_code(@user.otp_provisioning_uri)
    end
  end

  def create
    if params[:otp_code].blank?
      begin_two_factor_step_up
    elsif recent_two_factor_step_up? && @user.verify_otp(params[:otp_code])
      @user.enable_otp!
      session.delete(:two_factor_step_up_at)
      redirect_to profile_path, notice: t("flash.two_factor.create.notice")
    elsif !recent_two_factor_step_up?
      redirect_to profile_path, alert: t("flash.two_factor.current_password_required")
    else
      @qr_code = generate_qr_code(@user.otp_provisioning_uri)
      flash.now[:alert] = t("flash.two_factor.create.alert")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.authenticate(params[:current_password]) && @user.verify_otp(params[:otp_code])
      @user.disable_otp!
      redirect_to profile_path, notice: t("flash.two_factor.destroy.notice")
    else
      redirect_to profile_path, alert: t("flash.two_factor.destroy.alert")
    end
  end

  private

  def set_user
    @user = current_user
  end

  def generate_qr_code(uri)
    return nil unless uri
    RQRCode::QRCode.new(uri)
  end

  def begin_two_factor_step_up
    if !@user.otp_required? && @user.authenticate(params[:current_password])
      session[:two_factor_step_up_at] = Time.current.to_i
      redirect_to new_two_factor_path
    else
      redirect_to profile_path, alert: t("flash.two_factor.current_password_required")
    end
  end

  def recent_two_factor_step_up?
    session[:two_factor_step_up_at].to_i >= 5.minutes.ago.to_i
  end
end
