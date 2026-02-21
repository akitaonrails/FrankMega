require "test_helper"

class AllowedMimeTypeTest < ActiveSupport::TestCase
  test "requires mime_type" do
    mime = AllowedMimeType.new(description: "Test")
    assert_not mime.valid?
    assert_includes mime.errors[:mime_type], "can't be blank"
  end

  test "requires unique mime_type" do
    AllowedMimeType.create!(mime_type: "text/plain", description: "Text")
    dupe = AllowedMimeType.new(mime_type: "text/plain", description: "Text 2")
    assert_not dupe.valid?
  end

  test "enabled_types returns only enabled MIME types" do
    AllowedMimeType.create!(mime_type: "text/plain", description: "Text", enabled: true)
    AllowedMimeType.create!(mime_type: "text/html", description: "HTML", enabled: false)

    types = AllowedMimeType.enabled_types
    assert_includes types, "text/plain"
    assert_not_includes types, "text/html"
  end

  test "enabled scope filters correctly" do
    enabled = AllowedMimeType.create!(mime_type: "image/png", description: "PNG", enabled: true)
    disabled = AllowedMimeType.create!(mime_type: "image/gif", description: "GIF", enabled: false)

    assert_includes AllowedMimeType.enabled, enabled
    assert_not_includes AllowedMimeType.enabled, disabled
  end

  test "seed_defaults creates standard types" do
    AllowedMimeType.seed_defaults!
    assert AllowedMimeType.exists?(mime_type: "application/pdf")
    assert AllowedMimeType.exists?(mime_type: "image/jpeg")
    assert AllowedMimeType.exists?(mime_type: "text/plain")
  end

  test "seed_defaults is idempotent" do
    AllowedMimeType.seed_defaults!
    count = AllowedMimeType.count
    AllowedMimeType.seed_defaults!
    assert_equal count, AllowedMimeType.count
  end
end
