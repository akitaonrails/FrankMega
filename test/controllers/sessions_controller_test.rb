require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email_address: "test@example.com", password: "password123!safe")
  end

  test "shows login form" do
    get new_session_path
    assert_response :success
  end

  test "login with valid credentials" do
    post session_path, params: { email_address: "test@example.com", password: "password123!safe" }
    assert_redirected_to root_path
  end

  test "login with invalid credentials" do
    post session_path, params: { email_address: "test@example.com", password: "wrong" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_match(/Try another/, response.body)
  end

  test "banned user cannot login" do
    @user.ban!
    post session_path, params: { email_address: "test@example.com", password: "password123!safe" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_match(/suspended/, response.body)
  end

  test "user with OTP redirected to 2FA" do
    @user.generate_otp_secret!
    @user.enable_otp!

    post session_path, params: { email_address: "test@example.com", password: "password123!safe" }
    assert_redirected_to new_two_factor_session_path
  end

  test "logout destroys session" do
    post session_path, params: { email_address: "test@example.com", password: "password123!safe" }

    delete session_path
    assert_redirected_to new_session_path
  end
end
