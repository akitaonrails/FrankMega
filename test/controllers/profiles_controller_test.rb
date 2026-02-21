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

  test "deletes own account" do
    assert_difference "User.count", -1 do
      delete profile_path
    end
    assert_redirected_to new_session_path
    assert_nil User.find_by(id: @user.id)
  end

  test "deletes associated files when account deleted" do
    create(:shared_file, user: @user)
    assert_difference "SharedFile.count", -1 do
      delete profile_path
    end
  end

  test "sole admin cannot delete own account" do
    admin = create(:user, :admin, email_address: "admin@example.com", password: "password123!safe")
    delete session_path
    post session_path, params: { email_address: "admin@example.com", password: "password123!safe" }

    assert_no_difference "User.count" do
      delete profile_path
    end
    assert_redirected_to profile_path
    follow_redirect!
    assert_match I18n.t("flash.profiles.destroy.sole_admin"), response.body
  end

  test "requires authentication to delete account" do
    delete session_path
    delete profile_path
    assert_redirected_to new_session_path
  end
end
