require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = build(:user)
    assert user.valid?
  end

  test "requires email_address" do
    user = build(:user, email_address: nil)
    assert_not user.valid?
  end

  test "requires unique email_address" do
    create(:user, email_address: "test@example.com")
    user = build(:user, email_address: "test@example.com")
    assert_not user.valid?
  end

  test "normalizes email to lowercase" do
    user = create(:user, email_address: "TEST@EXAMPLE.COM")
    assert_equal "test@example.com", user.email_address
  end

  test "role defaults to user" do
    user = User.new
    assert_equal "user", user.role
  end

  test "admin? returns true for admin role" do
    user = build(:user, :admin)
    assert user.admin?
  end

  test "admin? returns false for user role" do
    user = build(:user)
    assert_not user.admin?
  end

  test "ban! sets banned and destroys sessions" do
    user = create(:user)
    create(:session, user: user)
    assert_equal 1, user.sessions.count

    user.ban!
    assert user.banned?
    assert_not_nil user.banned_at
    assert_equal 0, user.sessions.reload.count
  end

  test "unban! clears banned state" do
    user = create(:user, :banned)
    user.unban!
    assert_not user.banned?
    assert_nil user.banned_at
  end

  test "OTP generation and verification" do
    user = create(:user)
    user.generate_otp_secret!
    assert user.otp_secret.present?

    totp = ROTP::TOTP.new(user.otp_secret)
    code = totp.now
    assert user.verify_otp(code)
    assert_not user.verify_otp("000000")
  end

  test "enable and disable OTP" do
    user = create(:user)
    user.generate_otp_secret!
    user.enable_otp!
    assert user.otp_required?

    user.disable_otp!
    assert_not user.otp_required?
    assert_nil user.otp_secret
  end

  test "otp_provisioning_uri returns URI when secret present" do
    user = create(:user)
    user.generate_otp_secret!
    assert user.otp_provisioning_uri.present?
    assert user.otp_provisioning_uri.include?("otpauth://")
  end
end
