require "test_helper"

class CleanupExpiredBansJobTest < ActiveJob::TestCase
  test "removes expired bans" do
    expired = Ban.create!(ip_address: "1.1.1.1", reason: "test", expires_at: 1.hour.ago)
    active = Ban.ban!("2.2.2.2", reason: "test", duration: 1.hour)

    CleanupExpiredBansJob.perform_now

    assert_not Ban.exists?(expired.id)
    assert Ban.exists?(active.id)
  end

  test "does nothing when no expired bans" do
    active = Ban.ban!("3.3.3.3", reason: "test", duration: 1.hour)

    CleanupExpiredBansJob.perform_now

    assert Ban.exists?(active.id)
  end
end
