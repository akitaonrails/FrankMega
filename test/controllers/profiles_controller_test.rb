require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email_address: "profile@example.com", password: "password123!safe")
    post session_path, params: { email_address: "profile@example.com", password: "password123!safe" }
  end

  test "shows profile page" do
    get profile_path
    assert_response :success
    assert_match @user.email_address, response.body
  end

  test "updates password successfully" do
    patch profile_path, params: {
      user: { password: "newpassword1234", password_confirmation: "newpassword1234" }
    }
    assert_redirected_to profile_path
  end

  test "rejects mismatched password update" do
    patch profile_path, params: {
      user: { password: "newpassword1234", password_confirmation: "different123456" }
    }
    assert_response :unprocessable_entity
  end

  test "rejects short password update" do
    patch profile_path, params: {
      user: { password: "short", password_confirmation: "short" }
    }
    assert_response :unprocessable_entity
  end

  test "requires authentication" do
    delete session_path
    get profile_path
    assert_redirected_to new_session_path
  end
end
