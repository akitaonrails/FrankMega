require "test_helper"

class ChunkedUploadStoreTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  teardown do
    FileUtils.rm_rf(ChunkedUploadStore.root)
    Array(@paths).each { |path| FileUtils.rm_f(path) }
  end

  test "rejects undersized and oversized non-final chunks" do
    with_chunk_size(5) do
      upload = create_upload(10)

      assert_raises(ChunkedUploadStore::Error) { upload.write_chunk!(index: 0, upload: uploaded_chunk("tiny")) }
      assert_raises(ChunkedUploadStore::Error) { upload.write_chunk!(index: 0, upload: uploaded_chunk("toolong")) }
    end
  end

  test "requires the exact final chunk remainder" do
    with_chunk_size(5) do
      upload = create_upload(12)

      assert_raises(ChunkedUploadStore::Error) { upload.write_chunk!(index: 2, upload: uploaded_chunk("x")) }
      upload.write_chunk!(index: 2, upload: uploaded_chunk("ok"))
      assert ChunkedUploadStore.find!(upload.id, user: @user)
    end
  end

  test "rejects a sixth pending upload session" do
    5.times { create_upload(1) }

    assert_raises(ChunkedUploadStore::Error) { create_upload(1) }
  end

  test "rejects pending declared bytes beyond remaining quota and grace" do
    @user.update!(disk_quota_bytes: 10)
    grace = Rails.application.config.x.security.disk_quota_grace_bytes
    create_upload(grace + 10)

    assert_raises(ChunkedUploadStore::Error) { create_upload(1) }
  end

  private

  def create_upload(byte_size)
    ChunkedUploadStore.create!(
      user: @user,
      filename: "file.txt",
      byte_size: byte_size,
      content_type: "text/plain",
      shared_file_params: { max_downloads: 5, ttl_hours: 24 }
    )
  end

  def uploaded_chunk(contents)
    path = Rails.root.join("tmp/chunked-upload-#{SecureRandom.hex(8)}")
    File.binwrite(path, contents)
    (@paths ||= []) << path
    Rack::Test::UploadedFile.new(path, "application/octet-stream", true)
  end

  def with_chunk_size(size)
    original_size = Rails.application.config.x.security.upload_chunk_size_bytes
    Rails.application.config.x.security.upload_chunk_size_bytes = size
    yield
  ensure
    Rails.application.config.x.security.upload_chunk_size_bytes = original_size
  end
end
