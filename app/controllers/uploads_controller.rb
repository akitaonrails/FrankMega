class UploadsController < ApplicationController
  def new
    @shared_file = SharedFile.new(max_downloads: 5, ttl_hours: 24)
  end

  def create
    @shared_file = current_user.shared_files.new(upload_params)

    if params[:file].present?
      @shared_file.file.attach(params[:file])
      @shared_file.original_filename = params[:file].original_filename
      @shared_file.content_type = params[:file].content_type
      @shared_file.file_size = params[:file].size
    end

    if @shared_file.save
      redirect_to upload_path(@shared_file)
    else
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
    redirect_to dashboard_path, notice: "File deleted."
  end

  private

  def upload_params
    params.require(:shared_file).permit(:max_downloads, :ttl_hours)
  end

  def download_url(shared_file)
    "#{request.base_url}/d/#{shared_file.download_hash}"
  end
end
