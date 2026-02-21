require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin, email_address: "admin@example.com", password: "password123")
      post session_path, params: { email_address: "admin@example.com", password: "password123" }
    end

    test "admin can access users list" do
      get admin_users_path
      assert_response :success
    end

    test "admin can view user" do
      user = create(:user)
      get admin_user_path(user)
      assert_response :success
    end

    test "admin can ban user" do
      user = create(:user)
      post ban_admin_user_path(user)
      assert user.reload.banned?
      assert_redirected_to admin_user_path(user)
    end

    test "admin can unban user" do
      user = create(:user, :banned)
      post unban_admin_user_path(user)
      assert_not user.reload.banned?
    end

    test "admin can reset password" do
      user = create(:user)
      post reset_password_admin_user_path(user)
      assert_redirected_to admin_user_path(user)
    end

    test "non-admin redirected from admin panel" do
      delete session_path # logout admin

      regular = create(:user, email_address: "user@example.com", password: "password123")
      post session_path, params: { email_address: "user@example.com", password: "password123" }

      get admin_users_path
      assert_redirected_to root_path
    end

    test "admin can create invitation" do
      assert_difference "Invitation.count", 1 do
        post admin_invitations_path, params: {
          invitation: { expires_at: 7.days.from_now }
        }
      end
      assert_redirected_to admin_invitations_path
    end
  end
end
