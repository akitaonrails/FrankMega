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
      if removing_last_admin?
        redirect_to admin_user_path(@user), alert: "Cannot remove admin role from the last admin."
        return
      end

      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user.sole_admin?
        redirect_to admin_user_path(@user), alert: "Cannot delete the last admin."
        return
      end

      @user.destroy
      redirect_to admin_users_path, notice: "User deleted."
    end

    def ban
      if @user.sole_admin?
        redirect_to admin_user_path(@user), alert: "Cannot ban the last admin."
        return
      end

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
      flash[:temp_password] = new_password
      redirect_to admin_user_path(@user)
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email_address, :role)
    end

    def removing_last_admin?
      @user.admin? && user_params[:role] == "user" && User.admins.count <= 1
    end
  end
end
