module Admin
  class UsersController < Admin::ApplicationController
    before_action :set_user, only: %i[show edit update destroy ban unban reset_password]

    def index
      @users = User
        .left_joins(:shared_files)
        .select("users.*, COUNT(shared_files.id) AS files_count, COALESCE(SUM(shared_files.file_size), 0) AS total_storage")
        .group("users.id")
        .order(created_at: :desc)
    end

    def show
      @shared_files = @user.shared_files.order(created_at: :desc)
      @sessions = @user.sessions.order(created_at: :desc)
    end

    def edit
    end

    def update
      if removing_last_admin?
        redirect_to admin_user_path(@user), alert: t("flash.admin.users.update.last_admin_role")
        return
      end

      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: t("flash.admin.users.update.notice")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user.sole_admin?
        redirect_to admin_user_path(@user), alert: t("flash.admin.users.destroy.last_admin")
        return
      end

      @user.destroy
      redirect_to admin_users_path, notice: t("flash.admin.users.destroy.notice")
    end

    def ban
      if @user.sole_admin?
        redirect_to admin_user_path(@user), alert: t("flash.admin.users.ban.last_admin")
        return
      end

      @user.ban!
      redirect_to admin_user_path(@user), notice: t("flash.admin.users.ban.notice")
    end

    def unban
      @user.unban!
      redirect_to admin_user_path(@user), notice: t("flash.admin.users.unban.notice")
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
      permitted = params.require(:user).permit(:email_address, :role, :disk_quota_gb)
      if permitted.key?(:disk_quota_gb)
        gb_value = permitted.delete(:disk_quota_gb)
        permitted[:disk_quota_bytes] = gb_value.present? ? (gb_value.to_f * 1.gigabyte).round : nil
      end
      permitted
    end

    def removing_last_admin?
      @user.admin? && user_params[:role] == "user" && User.admins.count <= 1
    end
  end
end
