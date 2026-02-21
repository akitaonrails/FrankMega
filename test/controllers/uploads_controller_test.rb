require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email_address: "uploader@example.com", password: "password123")
    post session_path, params: { email_address: "uploader@example.com", password: "password123" }
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
end
