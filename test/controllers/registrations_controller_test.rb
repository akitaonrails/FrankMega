require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @invitation = create(:invitation)
  end

  test "shows registration form with valid invitation" do
    get register_path(code: @invitation.code)
    assert_response :success
  end

  test "redirects with invalid invitation code" do
    get register_path(code: "invalid_code")
    assert_redirected_to new_session_path
  end

  test "redirects with expired invitation" do
    expired = create(:invitation, :expired)
    get register_path(code: expired.code)
    assert_redirected_to new_session_path
  end

  test "creates user with valid invitation" do
    assert_difference "User.count", 1 do
      post register_path(code: @invitation.code), params: {
        user: {
          email_address: "new@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to root_path
    assert @invitation.reload.used?
  end

  test "does not create user with used invitation" do
    @invitation.redeem!(create(:user))

    get register_path(code: @invitation.code)
    assert_redirected_to new_session_path
  end
end
