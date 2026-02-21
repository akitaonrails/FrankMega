class SetupController < ApplicationController
  allow_unauthenticated_access

  before_action :ensure_no_users

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.role = "admin"

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: t("flash.setup.create.notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def ensure_no_users
    return if User.count.zero?
    redirect_to root_path
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
