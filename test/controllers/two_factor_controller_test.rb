require "test_helper"

class TwoFactorControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email_address: "2fa@example.com", password: "password123!safe")
    post session_path, params: { email_address: "2fa@example.com", password: "password123!safe" }
  end

  test "shows 2FA setup page with QR code" do
    get new_two_factor_path
    assert_response :success
    @user.reload
    assert @user.otp_secret.present?, "OTP secret should be generated"
  end

  test "enables 2FA with valid code" do
    @user.generate_otp_secret!
    totp = ROTP::TOTP.new(@user.otp_secret)

    post two_factor_path, params: { otp_code: totp.now }
    assert_redirected_to profile_path
    assert @user.reload.otp_required?
  end

  test "rejects invalid code during setup" do
    @user.generate_otp_secret!

    post two_factor_path, params: { otp_code: "000000" }
    assert_response :unprocessable_entity
    assert_not @user.reload.otp_required?
  end

  test "disables 2FA with valid code" do
    @user.generate_otp_secret!
    @user.enable_otp!
    totp = ROTP::TOTP.new(@user.otp_secret)

    delete two_factor_path, params: { otp_code: totp.now }
    assert_redirected_to profile_path
    assert_not @user.reload.otp_required?
  end

  test "rejects invalid code during disable" do
    @user.generate_otp_secret!
    @user.enable_otp!

    delete two_factor_path, params: { otp_code: "000000" }
    assert_redirected_to profile_path
    assert @user.reload.otp_required?, "2FA should still be enabled"
  end

  test "requires authentication" do
    delete session_path
    get new_two_factor_path
    assert_redirected_to new_session_path
  end
end
