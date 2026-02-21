require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "shows forgot password form" do
    get new_password_path
    assert_response :success
  end

  test "sends reset email for existing user" do
    user = create(:user, email_address: "reset@example.com")

    assert_enqueued_emails 1 do
      post passwords_path, params: { email_address: "reset@example.com" }
    end
    assert_redirected_to new_session_path
  end

  test "does not reveal whether email exists" do
    post passwords_path, params: { email_address: "nonexistent@example.com" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_match(/Password reset instructions sent/, response.body)
  end

  test "edit with valid token shows reset form" do
    user = create(:user)
    token = user.password_reset_token

    get edit_password_path(token: token)
    assert_response :success
  end

  test "edit with invalid token redirects" do
    get edit_password_path(token: "invalid_token")
    assert_redirected_to new_password_path
  end

  test "update with matching passwords resets and destroys sessions" do
    user = create(:user)
    create(:session, user: user)
    token = user.password_reset_token

    patch password_path(token: token), params: {
      password: "newsecurepass12",
      password_confirmation: "newsecurepass12"
    }
    assert_redirected_to new_session_path
    assert_equal 0, user.sessions.reload.count
  end

  test "update with mismatched passwords shows error" do
    user = create(:user)
    token = user.password_reset_token

    patch password_path(token: token), params: {
      password: "newsecurepass12",
      password_confirmation: "different12345"
    }
    assert_redirected_to edit_password_path(token: token)
  end
end
