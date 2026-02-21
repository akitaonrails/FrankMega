class ProfilesController < ApplicationController
  def show
    @user = current_user
    @webauthn_credentials = @user.webauthn_credentials
    @sessions = @user.sessions.order(created_at: :desc)
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to profile_path, notice: t("flash.profiles.update.notice")
    else
      @webauthn_credentials = @user.webauthn_credentials
      @sessions = @user.sessions.order(created_at: :desc)
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.sole_admin?
      redirect_to profile_path, alert: t("flash.profiles.destroy.sole_admin")
    else
      current_user.destroy
      reset_session
      redirect_to new_session_path, notice: t("flash.profiles.destroy.notice")
    end
  end

  private

  def profile_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
