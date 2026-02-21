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
      @shared_file.content_type = Marcel::MimeType.for(uploaded.tempfile, name: uploaded.original_filename)
      @shared_file.original_filename = sanitize_filename(uploaded.original_filename, @shared_file.content_type)
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

  KNOWN_EXTENSIONS = %w[
    jpg jpeg png gif webp bmp tiff tif svg ico
    pdf doc docx xls xlsx ppt pptx odt ods odp rtf
    zip gz bz2 xz tar rar 7z
    mp3 mp4 m4a m4v avi mov mkv wmv flv webm wav flac ogg aac
    txt csv json xml yaml yml html htm css js rb py sh md
  ].freeze

  def sanitize_filename(name, content_type = nil)
    sanitized = File.basename(name.to_s)
    sanitized = sanitized.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    sanitized = sanitized.gsub(/[\x00-\x1f\x7f\/\\:*?"<>|]/, "")
    sanitized = sanitized.sub(/\A\.+/, "")
    sanitized = sanitized.gsub(/\s+/, " ").strip

    base_without_ext = sanitized.sub(/\.[^.]*\z/, "")
    if base_without_ext.match?(/\A(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])\z/i)
      sanitized = "_#{sanitized}"
    end

    sanitized = strip_extension_junk(sanitized, content_type)
    sanitized = truncate_filename(sanitized, 255)
    sanitized.presence || "unnamed_file"
  end

  def strip_extension_junk(name, content_type)
    ext_pattern = KNOWN_EXTENSIONS.join("|")

    # Detect a known extension followed by _, comma, or + (URL artifact junk)
    match = name.match(/\A(.+?)\.(#{ext_pattern})[_,+]/i)
    return name unless match

    clean_name = "#{match[1]}.#{match[2]}"

    # Replace with correct extension if content_type is known and differs
    if content_type
      correct_ext = MiniMime.lookup_by_content_type(content_type)&.extension
      if correct_ext && !clean_name.downcase.end_with?(".#{correct_ext.downcase}")
        clean_name = "#{match[1]}.#{correct_ext}"
      end
    end

    clean_name
  end

  def truncate_filename(name, max_bytes)
    return name if name.bytesize <= max_bytes

    ext = File.extname(name)
    base = File.basename(name, ext)
    max_base = max_bytes - ext.bytesize
    return ext.byteslice(0, max_bytes) if max_base <= 0

    base = base.chop while base.bytesize > max_base
    "#{base}#{ext}"
  end
end
