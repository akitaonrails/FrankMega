require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
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
end
