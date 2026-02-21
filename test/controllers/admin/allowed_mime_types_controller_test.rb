require "test_helper"

module Admin
  class AllowedMimeTypesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin, email_address: "admin@example.com", password: "password123!safe")
      post session_path, params: { email_address: "admin@example.com", password: "password123!safe" }
    end

    test "lists allowed MIME types" do
      get admin_allowed_mime_types_path
      assert_response :success
    end

    test "shows new MIME type form" do
      get new_admin_allowed_mime_type_path
      assert_response :success
    end

    test "creates MIME type" do
      assert_difference "AllowedMimeType.count", 1 do
        post admin_allowed_mime_types_path, params: {
          allowed_mime_type: { mime_type: "application/xml", description: "XML File", enabled: true }
        }
      end
      assert_redirected_to admin_allowed_mime_types_path
    end

    test "destroys MIME type" do
      mime = AllowedMimeType.create!(mime_type: "text/html", description: "HTML", enabled: true)

      assert_difference "AllowedMimeType.count", -1 do
        delete admin_allowed_mime_type_path(mime)
      end
      assert_redirected_to admin_allowed_mime_types_path
    end

    test "non-admin cannot access MIME types" do
      delete session_path
      user = create(:user, email_address: "user@example.com", password: "password123!safe")
      post session_path, params: { email_address: "user@example.com", password: "password123!safe" }

      get admin_allowed_mime_types_path
      assert_redirected_to root_path
    end
  end
end
