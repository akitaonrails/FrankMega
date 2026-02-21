class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  before_action :set_invitation
  before_action :ensure_invitation_valid

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    ActiveRecord::Base.transaction do
      @user.save!
      @invitation.redeem!(@user)
    end

    start_new_session_for @user
    redirect_to root_path, notice: t("flash.registrations.create.notice")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def set_invitation
    @invitation = Invitation.find_by(code: params[:code])
  end

  def ensure_invitation_valid
    if @invitation.nil? || !@invitation.pending?
      redirect_to new_session_path, alert: t("flash.registrations.create.invalid_invitation")
    end
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
