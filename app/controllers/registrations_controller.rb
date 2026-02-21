class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  before_action :set_invitation
  before_action :ensure_invitation_valid

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      @invitation.redeem!(@user)
      start_new_session_for @user
      redirect_to root_path, notice: "Account created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by(code: params[:code])
  end

  def ensure_invitation_valid
    if @invitation.nil? || !@invitation.pending?
      redirect_to new_session_path, alert: "Invalid or expired invitation."
    end
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
