require "test_helper"

class SharedFileTest < ActiveSupport::TestCase
  test "valid shared file" do
    shared_file = build(:shared_file)
    assert shared_file.valid?
  end

  test "generates download_hash on creation" do
    shared_file = create(:shared_file)
    assert shared_file.download_hash.present?
  end

  test "download_hash is unique" do
    sf1 = create(:shared_file)
    sf2 = build(:shared_file, download_hash: sf1.download_hash)
    assert_not sf2.valid?
  end

  test "sets expires_at based on ttl_hours" do
    shared_file = create(:shared_file, ttl_hours: 12)
    assert_in_delta 12.hours.from_now, shared_file.expires_at, 5.seconds
  end

  test "validates max_downloads range" do
    assert_not build(:shared_file, max_downloads: 0).valid?
    assert_not build(:shared_file, max_downloads: 11).valid?
    assert build(:shared_file, max_downloads: 10).valid?
  end

  test "validates ttl_hours range" do
    assert_not build(:shared_file, ttl_hours: 0).valid?
    assert_not build(:shared_file, ttl_hours: 25).valid?
    assert build(:shared_file, ttl_hours: 12).valid?
  end

  test "validates file_size max 1GB" do
    assert_not build(:shared_file, file_size: 2.gigabytes).valid?
    assert build(:shared_file, file_size: 500.megabytes).valid?
  end

  test "active? returns true for valid file" do
    shared_file = create(:shared_file)
    assert shared_file.active?
  end

  test "expired? returns true for past expires_at" do
    shared_file = create(:shared_file, :expired)
    assert shared_file.expired?
    assert_not shared_file.active?
  end

  test "exhausted? returns true when downloads maxed" do
    shared_file = create(:shared_file, :exhausted)
    assert shared_file.exhausted?
    assert_not shared_file.active?
  end

  test "downloads_remaining calculation" do
    shared_file = create(:shared_file, max_downloads: 5, download_count: 3)
    assert_equal 2, shared_file.downloads_remaining
  end

  test "increment_download! increases count" do
    shared_file = create(:shared_file, download_count: 0)
    shared_file.increment_download!
    assert_equal 1, shared_file.reload.download_count
  end

  test "active scope returns only active files" do
    active = create(:shared_file)
    expired = create(:shared_file, :expired)
    exhausted = create(:shared_file, :exhausted)

    assert_includes SharedFile.active, active
    assert_not_includes SharedFile.active, expired
    assert_not_includes SharedFile.active, exhausted
  end

  test "inactive scope returns expired and exhausted" do
    active = create(:shared_file)
    expired = create(:shared_file, :expired)
    exhausted = create(:shared_file, :exhausted)

    assert_not_includes SharedFile.inactive, active
    assert_includes SharedFile.inactive, expired
    assert_includes SharedFile.inactive, exhausted
  end

  test "rejects upload when over quota plus grace" do
    user = create(:user, disk_quota_bytes: 1.gigabyte)
    create(:shared_file, user: user, file_size: 950.megabytes)
    file = build(:shared_file, user: user, file_size: 200.megabytes)
    assert_not file.valid?
    assert file.errors[:base].any? { |msg| msg.include?("storage quota") }
  end

  test "allows upload within grace buffer" do
    user = create(:user, disk_quota_bytes: 1.gigabyte)
    create(:shared_file, user: user, file_size: 950.megabytes)
    file = build(:shared_file, user: user, file_size: 150.megabytes)
    assert file.valid?
  end

  test "allows upload when under quota" do
    user = create(:user, disk_quota_bytes: 1.gigabyte)
    file = build(:shared_file, user: user, file_size: 500.megabytes)
    assert file.valid?
  end
end
