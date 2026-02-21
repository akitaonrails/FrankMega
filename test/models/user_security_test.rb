require "test_helper"

class UserSecurityTest < ActiveSupport::TestCase
  # -- Password minimum length --

  test "rejects password shorter than 12 characters" do
    user = build(:user, password: "short11char", password_confirmation: "short11char")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 12 characters)"
  end

  test "accepts password of exactly 12 characters" do
    user = build(:user, password: "exactly12chr", password_confirmation: "exactly12chr")
    assert user.valid?
  end

  test "accepts password up to bcrypt limit" do
    # bcrypt has a 72-byte max; Rails validates this
    pw = "a" * 72
    user = build(:user, password: pw, password_confirmation: pw)
    assert user.valid?
  end

  # -- OTP replay prevention --

  test "OTP code cannot be reused with same timestamp" do
    user = create(:user)
    user.generate_otp_secret!

    totp = ROTP::TOTP.new(user.otp_secret)
    code = totp.now

    assert user.verify_otp(code), "First use should succeed"
    assert_not user.verify_otp(code), "Replay with same code should fail"
  end

  test "OTP updates last_otp_at on successful verification" do
    user = create(:user)
    user.generate_otp_secret!

    assert_nil user.last_otp_at

    totp = ROTP::TOTP.new(user.otp_secret)
    user.verify_otp(totp.now)

    assert_not_nil user.reload.last_otp_at
  end

  test "OTP with no secret returns false" do
    user = create(:user)
    assert_not user.verify_otp("123456")
  end

  test "disable_otp clears last_otp_at" do
    user = create(:user)
    user.generate_otp_secret!
    user.enable_otp!

    totp = ROTP::TOTP.new(user.otp_secret)
    user.verify_otp(totp.now)
    assert_not_nil user.reload.last_otp_at

    user.disable_otp!
    assert_nil user.reload.last_otp_at
  end

  # -- Sole admin protection --

  test "sole_admin? returns true when only one admin exists" do
    admin = create(:user, :admin)
    assert admin.sole_admin?
  end

  test "sole_admin? returns false when multiple admins exist" do
    create(:user, :admin)
    admin2 = create(:user, :admin)
    assert_not admin2.sole_admin?
  end

  test "sole_admin? returns false for non-admin users" do
    create(:user, :admin)
    user = create(:user)
    assert_not user.sole_admin?
  end
end
