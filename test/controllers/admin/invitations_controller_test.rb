require "test_helper"

module Admin
  class InvitationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = create(:user, :admin, email_address: "admin@example.com", password: "password123!safe")
      post session_path, params: { email_address: "admin@example.com", password: "password123!safe" }
    end

    test "lists invitations" do
      create(:invitation, created_by: @admin)
      get admin_invitations_path
      assert_response :success
    end

    test "shows new invitation form" do
      get new_admin_invitation_path
      assert_response :success
    end

    test "creates invitation" do
      assert_difference "Invitation.count", 1 do
        post admin_invitations_path, params: {
          invitation: { expires_at: 7.days.from_now }
        }
      end
      assert_redirected_to admin_invitations_path
    end

    test "destroys invitation" do
      invitation = create(:invitation, created_by: @admin)

      assert_difference "Invitation.count", -1 do
        delete admin_invitation_path(invitation)
      end
      assert_redirected_to admin_invitations_path
    end

    test "non-admin cannot access invitations" do
      delete session_path
      user = create(:user, email_address: "user@example.com", password: "password123!safe")
      post session_path, params: { email_address: "user@example.com", password: "password123!safe" }

      get admin_invitations_path
      assert_redirected_to root_path
    end
  end
end
