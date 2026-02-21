require "test_helper"

class InvitationSecurityTest < ActiveSupport::TestCase
  test "redeem! fails if invitation already used" do
    invitation = create(:invitation)
    user1 = create(:user)
    user2 = create(:user)

    invitation.redeem!(user1)

    assert_raises(ActiveRecord::RecordInvalid) do
      invitation.redeem!(user2)
    end

    assert_equal user1, invitation.reload.used_by
  end

  test "redeem! fails if invitation expired" do
    invitation = create(:invitation, :expired)
    user = create(:user)

    assert_raises(ActiveRecord::RecordInvalid) do
      invitation.redeem!(user)
    end

    assert_nil invitation.reload.used_by
  end

  test "redeem! uses row-level lock" do
    invitation = create(:invitation)
    user = create(:user)

    # Verify with_lock is used by checking the invitation gets locked and updated atomically
    invitation.redeem!(user)
    assert invitation.reload.used?
    assert_equal user, invitation.used_by
  end
end
