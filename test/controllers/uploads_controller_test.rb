require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  teardown do
    FileUtils.rm_rf(ChunkedUploadStore.root)
    Array(@chunk_paths).each { |path| FileUtils.rm_f(path) }
    Array(@upload_paths).each { |path| FileUtils.rm_f(path) }
  end

  setup do
    @user = create(:user, email_address: "uploader@example.com", password: "password123!safe")
    post session_path, params: { email_address: "uploader@example.com", password: "password123!safe" }
  end

  test "shows upload form" do
    get new_upload_path
    assert_response :success
  end

  test "creates shared file with upload" do
    file = fixture_file_upload("test.txt", "text/plain")

    assert_difference "SharedFile.count", 1 do
      post uploads_path, params: {
        file: file,
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end
    assert_response :redirect
  end

  test "shows upload details" do
    shared_file = create(:shared_file, user: @user)
    get upload_path(shared_file)
    assert_response :success
  end

  test "deletes shared file" do
    shared_file = create(:shared_file, user: @user)

    assert_difference "SharedFile.count", -1 do
      delete upload_path(shared_file)
    end
    assert_redirected_to new_upload_path
  end

  test "cannot access another users file" do
    other_user = create(:user)
    shared_file = create(:shared_file, user: other_user)

    get upload_path(shared_file)
    assert_response :not_found
  end

  test "upload blocked when quota exceeded" do
    # Create file first, then tighten quota so existing usage exceeds quota + grace
    create(:shared_file, user: @user, file_size: 101.megabytes)
    @user.update!(disk_quota_bytes: 1.kilobyte)
    file = fixture_file_upload("test.txt", "text/plain")

    assert_no_difference "SharedFile.count" do
      post uploads_path, params: {
        file: file,
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end
    assert_response :unprocessable_entity
  end

  test "rejects zero-byte uploads" do
    path = Rails.root.join("tmp/empty-upload-#{SecureRandom.hex(8)}.txt")
    File.binwrite(path, "")
    (@upload_paths ||= []) << path

    assert_no_difference "SharedFile.count" do
      post uploads_path, params: {
        file: Rack::Test::UploadedFile.new(path, "text/plain", true),
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end

    assert_response :unprocessable_entity
  end

  test "quota recovers after file deletion" do
    @user.update!(disk_quota_bytes: 2.kilobytes)
    shared_file = create(:shared_file, user: @user, file_size: 2.kilobytes)

    delete upload_path(shared_file)

    file = fixture_file_upload("test.txt", "text/plain")
    assert_difference "SharedFile.count", 1 do
      post uploads_path, params: {
        file: file,
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end
    assert_response :redirect
  end

  test "sanitizes path traversal in filename" do
    file = fixture_file_upload("test.txt", "text/plain")
    # Stub original_filename to simulate path traversal
    file.define_singleton_method(:original_filename) { "../../etc/passwd" }

    assert_difference "SharedFile.count", 1 do
      post uploads_path, params: {
        file: file,
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end

    shared_file = SharedFile.last
    assert_equal "passwd", shared_file.original_filename
  end

  test "sanitizes control characters in filename" do
    file = fixture_file_upload("test.txt", "text/plain")
    file.define_singleton_method(:original_filename) { "file\x01\x02name.txt" }

    assert_difference "SharedFile.count", 1 do
      post uploads_path, params: {
        file: file,
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end

    shared_file = SharedFile.last
    assert_equal "filename.txt", shared_file.original_filename
  end

  test "truncates long filename preserving extension" do
    file = fixture_file_upload("test.txt", "text/plain")
    long_name = "#{"a" * 300}.txt"
    file.define_singleton_method(:original_filename) { long_name }

    assert_difference "SharedFile.count", 1 do
      post uploads_path, params: {
        file: file,
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end

    shared_file = SharedFile.last
    assert shared_file.original_filename.bytesize <= 255
    assert shared_file.original_filename.end_with?(".txt")
  end

  test "sanitizes Windows reserved names" do
    file = fixture_file_upload("test.txt", "text/plain")
    file.define_singleton_method(:original_filename) { "CON.txt" }

    assert_difference "SharedFile.count", 1 do
      post uploads_path, params: {
        file: file,
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end

    shared_file = SharedFile.last
    assert_equal "_CON.txt", shared_file.original_filename
  end

  test "sanitizes hidden filenames" do
    file = fixture_file_upload("test.txt", "text/plain")
    file.define_singleton_method(:original_filename) { ".hidden" }

    assert_difference "SharedFile.count", 1 do
      post uploads_path, params: {
        file: file,
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end

    shared_file = SharedFile.last
    assert_equal "hidden", shared_file.original_filename
  end

  test "strips URL junk after embedded file extension" do
    file = fixture_file_upload("test.txt", "text/plain")
    file.define_singleton_method(:original_filename) { "image.png_0,0,2140,2000+stuff.jpeg" }

    assert_difference "SharedFile.count", 1 do
      post uploads_path, params: {
        file: file,
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end

    shared_file = SharedFile.last
    assert_not_includes shared_file.original_filename, "_0,0,2140"
    assert shared_file.original_filename.end_with?(".txt") || shared_file.original_filename.end_with?(".png") || shared_file.original_filename.end_with?(".jpeg")
  end

  test "preserves normal filenames with multiple dots" do
    file = fixture_file_upload("test.txt", "text/plain")
    file.define_singleton_method(:original_filename) { "report.final.2024.txt" }

    assert_difference "SharedFile.count", 1 do
      post uploads_path, params: {
        file: file,
        shared_file: { max_downloads: 5, ttl_hours: 12 }
      }
    end

    shared_file = SharedFile.last
    assert_equal "report.final.2024.txt", shared_file.original_filename
  end

  test "starts chunked upload" do
    post start_chunked_upload_path, params: {
      filename: "deck.pptx",
      byte_size: 12.megabytes,
      content_type: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      shared_file: { max_downloads: 5, ttl_hours: 12 }
    }

    assert_response :created
    body = response.parsed_body
    assert body["upload_id"].present?
    assert_equal ChunkedUploadStore.chunk_size, body["chunk_size"]
    assert_equal 1, body["total_chunks"]
  end

  test "creates shared file from chunked upload" do
    content = "hello chunked upload"
    start_chunked_upload(content.bytesize)
    upload_id = response.parsed_body.fetch("upload_id")

    assert_difference "SharedFile.count", 1 do
      post chunked_upload_chunks_path(upload_id), params: {
        index: 0,
        chunk: uploaded_chunk(content)
      }
      assert_response :success

      post complete_chunked_upload_path(upload_id)
      assert_response :created
    end

    shared_file = SharedFile.last
    assert_equal "deck.txt", shared_file.original_filename
    assert_equal content.bytesize, shared_file.file_size
    assert shared_file.file.attached?
    assert_equal upload_path(shared_file), response.parsed_body.fetch("redirect_url")
  end

  test "creates shared file from multiple chunks" do
    content = "hello chunked upload"

    with_chunk_size(5) do
      start_chunked_upload(content.bytesize)
      upload_id = response.parsed_body.fetch("upload_id")
      assert_equal 4, response.parsed_body.fetch("total_chunks")

      assert_difference "SharedFile.count", 1 do
        content.bytes.each_slice(5).with_index do |bytes, index|
          post chunked_upload_chunks_path(upload_id), params: {
            index: index,
            chunk: uploaded_chunk(bytes.pack("C*"))
          }
          assert_response :success
        end

        post complete_chunked_upload_path(upload_id)
        assert_response :created
      end
    end

    assert_equal content.bytesize, SharedFile.last.file_size
  end

  test "chunked upload completion rejects missing chunks" do
    with_chunk_size(5) do
      start_chunked_upload(10)
      upload_id = response.parsed_body.fetch("upload_id")

      post chunked_upload_chunks_path(upload_id), params: {
        index: 0,
        chunk: uploaded_chunk("hello")
      }
      assert_response :success

      assert_no_difference "SharedFile.count" do
        post complete_chunked_upload_path(upload_id)
      end
      assert_response :unprocessable_entity
      assert_includes response.parsed_body.fetch("errors").join, "incomplete"
    end
  end

  test "chunked upload start rejects files over configured max" do
    post start_chunked_upload_path, params: {
      filename: "huge.zip",
      byte_size: Rails.application.config.x.security.max_upload_size_bytes + 1,
      content_type: "application/zip",
      shared_file: { max_downloads: 5, ttl_hours: 12 }
    }

    assert_response :unprocessable_entity
    assert_includes response.parsed_body.fetch("errors").join, "maximum size"
  end

  private

  def start_chunked_upload(byte_size)
    post start_chunked_upload_path, params: {
      filename: "deck.txt",
      byte_size: byte_size,
      content_type: "text/plain",
      shared_file: { max_downloads: 5, ttl_hours: 12 }
    }
    assert_response :created
  end

  def uploaded_chunk(content)
    path = Rails.root.join("tmp/test-chunk-#{SecureRandom.hex(8)}")
    File.binwrite(path, content)
    (@chunk_paths ||= []) << path
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
