class DownloadsController < ApplicationController
  allow_unauthenticated_access

  before_action :find_shared_file
  before_action :check_owner_not_banned

  def show
    if @shared_file.nil?
      record_invalid_access
      render plain: "Not Found", status: :not_found
    elsif !@shared_file.active?
      render plain: "Gone", status: :gone
    end
  end

  def create
    if @shared_file.nil?
      record_invalid_access
      render plain: "Not Found", status: :not_found
    elsif !@shared_file.increment_download!
      render plain: "Gone", status: :gone
    else
      @shared_file.reload
      DownloadNotificationJob.perform_later(@shared_file.id)
      redirect_to rails_blob_path(@shared_file.file, disposition: "attachment")
    end
  end

  private

  def find_shared_file
    @shared_file = SharedFile.includes(:user).find_by(download_hash: params[:hash])
  end

  def check_owner_not_banned
    return if @shared_file.nil?

    render plain: "Gone", status: :gone if @shared_file.user.banned?
  end

  def record_invalid_access
    InvalidHashAccessJob.perform_later(request.remote_ip)
  end
end
