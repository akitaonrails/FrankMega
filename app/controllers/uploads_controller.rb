class UploadsController < ApplicationController
  def new
    @shared_file = SharedFile.new(max_downloads: 5, ttl_hours: 24)
    @active_files = current_user.shared_files.active.order(created_at: :desc)
    @inactive_files = current_user.shared_files.inactive.order(created_at: :desc)
    @storage_used = current_user.storage_used
    @disk_quota = current_user.disk_quota
  end

  def create
    @shared_file = current_user.shared_files.new(upload_params)

    if params[:file].present?
      uploaded = params[:file]
      @shared_file.file.attach(uploaded)
      @shared_file.original_filename = sanitize_filename(uploaded.original_filename)
      @shared_file.content_type = Marcel::MimeType.for(uploaded.tempfile, name: uploaded.original_filename)
      @shared_file.file_size = uploaded.tempfile.size
    end

    if @shared_file.save
      redirect_to upload_path(@shared_file)
    else
      @active_files = current_user.shared_files.active.order(created_at: :desc)
      @inactive_files = current_user.shared_files.inactive.order(created_at: :desc)
      @storage_used = current_user.storage_used
      @disk_quota = current_user.disk_quota
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @shared_file = current_user.shared_files.find(params[:id])
    @qr_code = RQRCode::QRCode.new(download_url(@shared_file))
  end

  def destroy
    @shared_file = current_user.shared_files.find(params[:id])
    @shared_file.file.purge
    @shared_file.destroy
    redirect_to new_upload_path, notice: t("flash.uploads.destroy.notice")
  end

  private

  def upload_params
    params.require(:shared_file).permit(:max_downloads, :ttl_hours)
  end

  def download_url(shared_file)
    "#{request.base_url}/d/#{shared_file.download_hash}"
  end

  def sanitize_filename(name)
    basename = File.basename(name.to_s)
    sanitized = basename.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
                        .gsub(/[\x00\/\\]/, "")
                        .strip
    sanitized.presence || "unnamed_file"
  end
end
