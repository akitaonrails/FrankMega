require "test_helper"

class SharedFileSecurityTest < ActiveSupport::TestCase
  # -- Atomic download counter --

  test "increment_download! returns true when under limit" do
    sf = create(:shared_file, max_downloads: 5, download_count: 0)
    assert sf.increment_download!
    assert_equal 1, sf.reload.download_count
  end

  test "increment_download! returns false when at limit" do
    sf = create(:shared_file, max_downloads: 5, download_count: 5)
    assert_not sf.increment_download!
    assert_equal 5, sf.reload.download_count
  end

  test "increment_download! returns false for expired file" do
    sf = create(:shared_file, :expired, download_count: 0)
    assert_not sf.increment_download!
    assert_equal 0, sf.reload.download_count
  end

  test "increment_download! stops exactly at max_downloads" do
    sf = create(:shared_file, max_downloads: 3, download_count: 0)

    results = 5.times.map { sf.increment_download! }

    assert_equal 3, results.count(true), "Exactly 3 increments should succeed"
    assert_equal 2, results.count(false), "2 should fail"
    assert_equal 3, sf.reload.download_count
  end

  test "increment_download! does not exceed max even with concurrent calls" do
    sf = create(:shared_file, max_downloads: 1, download_count: 0)

    # Simulate rapid sequential calls (SQLite doesn't support true concurrency)
    first = sf.increment_download!
    second = sf.increment_download!

    assert first, "First increment should succeed"
    assert_not second, "Second increment should fail"
    assert_equal 1, sf.reload.download_count
  end
end
