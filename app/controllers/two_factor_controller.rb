class TwoFactorController < ApplicationController
  before_action :set_user

  def new
    @user.generate_otp_secret! unless @user.otp_secret.present?
    @qr_code = generate_qr_code(@user.otp_provisioning_uri)
  end

  def create
    if @user.verify_otp(params[:otp_code])
      @user.enable_otp!
      redirect_to profile_path, notice: "Two-factor authentication enabled."
    else
      @qr_code = generate_qr_code(@user.otp_provisioning_uri)
      flash.now[:alert] = "Invalid code. Please try again."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.verify_otp(params[:otp_code])
      @user.disable_otp!
      redirect_to profile_path, notice: "Two-factor authentication disabled."
    else
      redirect_to profile_path, alert: "Invalid code. 2FA not disabled."
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
end
