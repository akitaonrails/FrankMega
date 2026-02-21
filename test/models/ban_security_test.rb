require "test_helper"

class BanSecurityTest < ActiveSupport::TestCase
  test "ban! invalidates cache for the IP" do
    ip = "10.0.0.1"
    # Prime the cache with "not banned"
    assert_not Ban.banned?(ip)

    # Ban the IP — should invalidate cache
    Ban.ban!(ip, reason: "test", duration: 1.hour)

    # Should see the ban immediately (not stale cached value)
    assert Ban.banned?(ip)
  end

  test "ban! calls cache delete to invalidate" do
    ip = "10.0.0.2"

    # Verify cache.delete is called on ban
    cache_delete_called = false
    original_delete = Rails.cache.method(:delete)
    Rails.cache.define_singleton_method(:delete) do |key, *args|
      cache_delete_called = true if key == "ban:#{ip}"
      original_delete.call(key, *args)
    end

    Ban.ban!(ip, reason: "test", duration: 1.hour)
    assert cache_delete_called, "Ban.ban! should call Rails.cache.delete"
  ensure
    # Restore original method
    Rails.cache.singleton_class.remove_method(:delete) if Rails.cache.singleton_class.method_defined?(:delete)
  end

  test "banned? uses cache_fetch pattern" do
    ip = "10.0.0.3"

    # Verify that banned? goes through Rails.cache.fetch
    cache_fetch_called = false
    original_fetch = Rails.cache.method(:fetch)
    Rails.cache.define_singleton_method(:fetch) do |key, **opts, &block|
      cache_fetch_called = true if key == "ban:#{ip}"
      original_fetch.call(key, **opts, &block)
    end

    Ban.banned?(ip)
    assert cache_fetch_called, "Ban.banned? should use Rails.cache.fetch"
  ensure
    Rails.cache.singleton_class.remove_method(:fetch) if Rails.cache.singleton_class.method_defined?(:fetch)
  end
end
