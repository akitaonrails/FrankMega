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

  test "storage_used returns sum of file sizes" do
    user = create(:user)
    create(:shared_file, user: user, file_size: 1000)
    create(:shared_file, user: user, file_size: 2000)
    assert_equal 3000, user.storage_used
  end

  test "storage_used returns 0 with no files" do
    user = create(:user)
    assert_equal 0, user.storage_used
  end

  test "disk_quota returns system default when no override" do
    user = build(:user, disk_quota_bytes: nil)
    assert_equal Rails.application.config.x.security.default_disk_quota_bytes, user.disk_quota
  end

  test "disk_quota returns per-user override when set" do
    user = build(:user, disk_quota_bytes: 10.gigabytes)
    assert_equal 10.gigabytes, user.disk_quota
  end

  test "can_upload? allows within quota" do
    user = create(:user, disk_quota_bytes: 1.gigabyte)
    assert user.can_upload?(500.megabytes)
  end

  test "can_upload? allows within grace buffer" do
    user = create(:user, disk_quota_bytes: 1.gigabyte)
    create(:shared_file, user: user, file_size: 950.megabytes)
    assert user.can_upload?(150.megabytes)
  end

  test "can_upload? rejects over quota plus grace" do
    user = create(:user, disk_quota_bytes: 1.gigabyte)
    create(:shared_file, user: user, file_size: 950.megabytes)
    assert_not user.can_upload?(200.megabytes)
  end

  test "storage_remaining returns correct value" do
    user = create(:user, disk_quota_bytes: 1.gigabyte)
    create(:shared_file, user: user, file_size: 300.megabytes)
    assert_equal 1.gigabyte - 300.megabytes, user.storage_remaining
  end

  test "storage_remaining never goes negative" do
    user = create(:user, disk_quota_bytes: 100)
    create(:shared_file, user: user, file_size: 200)
    assert_equal 0, user.storage_remaining
  end
end
