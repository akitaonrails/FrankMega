require "test_helper"

class BanTest < ActiveSupport::TestCase
  test "ban! creates a ban record" do
    Ban.ban!("1.2.3.4", reason: "test", duration: 1.hour)
    assert Ban.banned?("1.2.3.4")
  end

  test "expired ban is not active" do
    Ban.create!(ip_address: "1.2.3.4", reason: "test", expires_at: 1.hour.ago)
    assert_not Ban.banned?("1.2.3.4")
  end

  test "active scope returns unexpired bans" do
    active = Ban.ban!("1.2.3.4", duration: 1.hour)
    expired = Ban.create!(ip_address: "5.6.7.8", reason: "test", expires_at: 1.hour.ago)

    assert_includes Ban.active, active
    assert_not_includes Ban.active, expired
  end

  test "cleanup removes expired bans" do
    Ban.create!(ip_address: "1.2.3.4", reason: "test", expires_at: 1.hour.ago)
    Ban.ban!("5.6.7.8", duration: 1.hour)

    Ban.expired.delete_all

    assert_equal 1, Ban.count
    assert Ban.banned?("5.6.7.8")
  end
end
