require "test_helper"

class TwoFactorSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :with_otp, email_address: "otp@example.com", password: "password123!safe")
    post session_path, params: { email_address: "otp@example.com", password: "password123!safe" }
    assert_redirected_to new_two_factor_session_path
  end

  test "shows 2FA verification form" do
    get new_two_factor_session_path
    assert_response :success
  end

  test "authenticates with valid OTP code" do
    totp = ROTP::TOTP.new(@user.otp_secret)
    post two_factor_session_path, params: { otp_code: totp.now }
    assert_response :redirect
  end

  test "rejects invalid OTP code" do
    post two_factor_session_path, params: { otp_code: "000000" }
    assert_response :unprocessable_entity
  end

  test "redirects without pending user" do
    reset!
    get new_two_factor_session_path
    assert_redirected_to new_session_path
  end

  test "clears pending_user_id after successful verification" do
    totp = ROTP::TOTP.new(@user.otp_secret)
    post two_factor_session_path, params: { otp_code: totp.now }

    # After 2FA success, should be fully authenticated
    get new_upload_path
    assert_response :success
  end
end
