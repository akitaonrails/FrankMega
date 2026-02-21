require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "generates code on creation" do
    invitation = create(:invitation)
    assert invitation.code.present?
  end

  test "code is unique" do
    inv1 = create(:invitation)
    inv2 = build(:invitation, code: inv1.code)
    assert_not inv2.valid?
  end

  test "pending? returns true for valid unused invitation" do
    invitation = create(:invitation)
    assert invitation.pending?
  end

  test "expired? returns true for past expires_at" do
    invitation = create(:invitation, :expired)
    assert invitation.expired?
    assert_not invitation.pending?
  end

  test "used? returns true when used_by is set" do
    invitation = create(:invitation, :used)
    assert invitation.used?
    assert_not invitation.pending?
  end

  test "status returns correct string" do
    assert_equal "pending", create(:invitation).status
    assert_equal "expired", create(:invitation, :expired).status
    assert_equal "used", create(:invitation, :used).status
  end

  test "redeem! marks invitation as used" do
    invitation = create(:invitation)
    user = create(:user)
    invitation.redeem!(user)

    assert invitation.used?
    assert_equal user, invitation.used_by
    assert_not_nil invitation.used_at
  end

  test "scopes return correct invitations" do
    pending = create(:invitation)
    expired = create(:invitation, :expired)
    used = create(:invitation, :used)

    assert_includes Invitation.pending, pending
    assert_not_includes Invitation.pending, expired
    assert_not_includes Invitation.pending, used

    assert_includes Invitation.expired, expired
    assert_includes Invitation.used, used
  end
end
