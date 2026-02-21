module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[show edit update destroy ban unban reset_password]

    def index
      @users = User.order(created_at: :desc)
    end

    def show
      @shared_files = @user.shared_files.order(created_at: :desc)
      @sessions = @user.sessions.order(created_at: :desc)
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      redirect_to admin_users_path, notice: "User deleted."
    end

    def ban
      @user.ban!
      redirect_to admin_user_path(@user), notice: "User banned."
    end

    def unban
      @user.unban!
      redirect_to admin_user_path(@user), notice: "User unbanned."
    end

    def reset_password
      new_password = SecureRandom.hex(8)
      @user.update!(password: new_password, password_confirmation: new_password)
      @user.sessions.destroy_all
      redirect_to admin_user_path(@user), notice: "Password reset to: #{new_password}"
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email_address, :role)
    end
  end
end
