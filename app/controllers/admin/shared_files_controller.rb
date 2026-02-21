module Admin
  class SharedFilesController < Admin::ApplicationController
    def index
      @shared_files = SharedFile.includes(:user).order(created_at: :desc)
    end

    def show
      @shared_file = SharedFile.find(params[:id])
    end

    def destroy
      shared_file = SharedFile.find(params[:id])
      shared_file.file.purge if shared_file.file.attached?
      shared_file.destroy
      redirect_to admin_shared_files_path, notice: t("flash.admin.shared_files.destroy.notice")
    end
  end
end
