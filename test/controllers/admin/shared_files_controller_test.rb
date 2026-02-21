require "test_helper"

module Admin
  class SharedFilesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin, email_address: "admin@example.com", password: "password123!safe")
      post session_path, params: { email_address: "admin@example.com", password: "password123!safe" }
    end

    test "lists all shared files" do
      create(:shared_file)
      get admin_shared_files_path
      assert_response :success
    end

    test "shows shared file details" do
      shared_file = create(:shared_file)
      get admin_shared_file_path(shared_file)
      assert_response :success
    end

    test "admin can delete any shared file" do
      shared_file = create(:shared_file)

      assert_difference "SharedFile.count", -1 do
        delete admin_shared_file_path(shared_file)
      end
      assert_redirected_to admin_shared_files_path
    end

    test "non-admin cannot access shared files" do
      delete session_path
      user = create(:user, email_address: "user@example.com", password: "password123!safe")
      post session_path, params: { email_address: "user@example.com", password: "password123!safe" }

      get admin_shared_files_path
      assert_redirected_to root_path
    end
  end
end
