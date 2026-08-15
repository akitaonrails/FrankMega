class ChunkedUploadStore
  class Error < StandardError; end

  EXPIRY = 6.hours
  ID_PATTERN = /\A[A-Za-z0-9_-]+\z/

  attr_reader :id, :metadata

  def self.create!(user:, filename:, byte_size:, content_type:, shared_file_params:)
    byte_size = Integer(byte_size)
    raise Error, I18n.t("uploads.chunked.errors.empty_file") if byte_size <= 0
    raise Error, I18n.t("uploads.chunked.errors.too_large", size: max_upload_size_label) if byte_size > max_upload_size

    user.with_lock do
      user.reload
      raise Error, I18n.t("uploads.chunked.errors.quota_exceeded") unless user.can_upload?(byte_size)
      raise Error, I18n.t("uploads.chunked.errors.too_many_pending") if pending_uploads_for(user).size >= 5

      pending_bytes = pending_uploads_for(user).sum { |metadata| Integer(metadata.fetch("byte_size")) }
      remaining_quota = user.disk_quota - user.storage_used + Rails.application.config.x.security.disk_quota_grace_bytes
      raise Error, I18n.t("uploads.chunked.errors.pending_quota_exceeded") if pending_bytes + byte_size > remaining_quota

      upload_id = SecureRandom.urlsafe_base64(24)
      upload = new(upload_id)
      upload.prepare!(
        user_id: user.id,
        filename: filename.to_s,
        byte_size: byte_size,
        content_type: content_type.to_s,
        max_downloads: shared_file_params[:max_downloads],
        ttl_hours: shared_file_params[:ttl_hours],
        total_chunks: (byte_size.to_f / chunk_size).ceil,
        chunk_size: chunk_size,
        created_at: Time.current.iso8601
      )
      upload
    end
  rescue ArgumentError, TypeError
    raise Error, I18n.t("uploads.chunked.errors.invalid_size")
  end

  def self.find!(id, user:)
    upload = new(id)
    upload.load!
    upload.ensure_user!(user)
    upload
  end

  def self.prune_expired!
    return unless root.exist?

    root.each_child do |path|
      next unless path.directory?
      metadata_path = path.join("metadata.json")
      created_at = metadata_path.exist? ? Time.iso8601(JSON.parse(metadata_path.read).fetch("created_at")) : path.mtime
      FileUtils.rm_rf(path) if created_at < EXPIRY.ago
    rescue JSON::ParserError, KeyError, ArgumentError
      FileUtils.rm_rf(path)
    end
  end

  def self.root
    root = Rails.root.join("tmp/chunked_uploads")
    Rails.env.test? ? root.join(ENV.fetch("TEST_ENV_NUMBER", Process.pid.to_s)) : root
  end

  def self.chunk_size
    Rails.application.config.x.security.upload_chunk_size_bytes
  end

  def self.max_upload_size
    Rails.application.config.x.security.max_upload_size_bytes
  end

  def self.max_upload_size_label
    ActionController::Base.helpers.number_to_human_size(max_upload_size)
  end

  def self.pending_uploads_for(user)
    return [] unless root.exist?

    Dir.glob(root.join("*/metadata.json")).filter_map do |metadata_path|
      metadata = JSON.parse(File.read(metadata_path))
      metadata if metadata["user_id"] == user.id
    rescue JSON::ParserError, Errno::ENOENT
      nil
    end
  end

  def initialize(id)
    raise Error, I18n.t("uploads.chunked.errors.invalid_upload") unless id.to_s.match?(ID_PATTERN)

    @id = id.to_s
    @metadata = nil
  end

  def prepare!(metadata)
    FileUtils.mkdir_p(chunks_path)
    metadata_path.write(JSON.generate(metadata))
    @metadata = metadata.stringify_keys
  end

  def load!
    raise Error, I18n.t("uploads.chunked.errors.not_found") unless metadata_path.exist?

    @metadata = JSON.parse(metadata_path.read)
  rescue JSON::ParserError
    raise Error, I18n.t("uploads.chunked.errors.not_found")
  end

  def ensure_user!(user)
    raise Error, I18n.t("uploads.chunked.errors.not_found") unless metadata.fetch("user_id") == user.id
  end

  def write_chunk!(index:, upload:)
    index = Integer(index)
    raise Error, I18n.t("uploads.chunked.errors.invalid_chunk") unless index.between?(0, total_chunks - 1)
    raise Error, I18n.t("uploads.chunked.errors.missing_chunk") unless upload.respond_to?(:tempfile)
    expected_size = index == total_chunks - 1 ? byte_size - declared_chunk_size * (total_chunks - 1) : declared_chunk_size
    raise Error, I18n.t("uploads.chunked.errors.chunk_size_mismatch") unless upload.tempfile.size == expected_size

    upload.tempfile.rewind
    FileUtils.mkdir_p(chunks_path)
    IO.copy_stream(upload.tempfile, chunk_path(index))
  rescue ArgumentError, TypeError
    raise Error, I18n.t("uploads.chunked.errors.invalid_chunk")
  ensure
    upload.tempfile.rewind if upload&.respond_to?(:tempfile)
  end

  def complete!(user:)
    missing = missing_chunks
    raise Error, I18n.t("uploads.chunked.errors.incomplete", count: missing.size) if missing.any?

    merge_chunks
    actual_size = File.size(merged_path)
    raise Error, I18n.t("uploads.chunked.errors.size_mismatch") unless actual_size == byte_size

    File.open(merged_path, "rb") do |file|
      user.with_lock do
        user.reload
        content_type = Marcel::MimeType.for(file, name: filename)
        file.rewind
        shared_file = user.shared_files.new(max_downloads: metadata.fetch("max_downloads"), ttl_hours: metadata.fetch("ttl_hours"))
        shared_file.original_filename = UploadFilenameSanitizer.call(filename, content_type)
        shared_file.content_type = content_type
        shared_file.file_size = actual_size
        shared_file.file.attach(io: file, filename: shared_file.original_filename, content_type: content_type)

        if shared_file.save
          cleanup!
        else
          shared_file.file.purge if shared_file.file.attached?
        end

        shared_file
      end
    end
  end

  def cleanup!
    FileUtils.rm_rf(path)
  end

  def total_chunks
    metadata.fetch("total_chunks")
  end

  def byte_size
    metadata.fetch("byte_size")
  end

  def declared_chunk_size
    metadata.fetch("chunk_size")
  end

  def filename
    metadata.fetch("filename")
  end

  private

  def path
    self.class.root.join(id)
  end

  def chunks_path
    path.join("chunks")
  end

  def metadata_path
    path.join("metadata.json")
  end

  def merged_path
    path.join("merged")
  end

  def chunk_path(index)
    chunks_path.join("#{index}.part")
  end

  def missing_chunks
    (0...total_chunks).reject { |index| chunk_path(index).exist? }
  end

  def merge_chunks
    File.open(merged_path, "wb") do |merged|
      (0...total_chunks).each do |index|
        File.open(chunk_path(index), "rb") { |chunk| IO.copy_stream(chunk, merged) }
      end
    end
  end
end
