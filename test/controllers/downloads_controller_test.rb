require "test_helper"

class DownloadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @shared_file = create(:shared_file)
  end

  test "shows download page for valid hash" do
    get download_path(hash: @shared_file.download_hash)
    assert_response :success
    assert_match @shared_file.original_filename, response.body
  end

  test "returns 404 for invalid hash" do
    get download_path(hash: "nonexistent_hash")
    assert_response :not_found
    assert_match "Link Not Found", response.body
  end

  test "returns 410 for expired file" do
    expired = create(:shared_file, :expired)
    get download_path(hash: expired.download_hash)
    assert_response :gone
    assert_match "Link Expired", response.body
  end

  test "returns 410 for exhausted downloads" do
    exhausted = create(:shared_file, :exhausted)
    get download_path(hash: exhausted.download_hash)
    assert_response :gone
    assert_match "Link Expired", response.body
  end

  test "download increments counter" do
    assert_difference -> { @shared_file.reload.download_count }, 1 do
      post download_file_path(hash: @shared_file.download_hash)
    end
  end

  test "download returns 404 for invalid hash" do
    post download_file_path(hash: "nonexistent_hash")
    assert_response :not_found
  end

  test "download returns 410 for expired file" do
    expired = create(:shared_file, :expired)
    post download_file_path(hash: expired.download_hash)
    assert_response :gone
  end

  test "returns 410 for banned user's file on show" do
    @shared_file.user.ban!
    get download_path(hash: @shared_file.download_hash)
    assert_response :gone
  end

  test "returns 410 for banned user's file on download" do
    @shared_file.user.ban!
    post download_file_path(hash: @shared_file.download_hash)
    assert_response :gone
  end

  test "allows download after user is unbanned" do
    @shared_file.user.ban!
    @shared_file.user.unban!
    get download_path(hash: @shared_file.download_hash)
    assert_response :success
  end

  # Preview action tests
  test "preview serves image inline" do
    image_file = create(:shared_file, :image)
    get download_preview_path(hash: image_file.download_hash)
    assert_response :success
    assert_equal "image/png", response.content_type
    assert_match "inline", response.headers["Content-Disposition"]
  end

  test "preview serves video inline" do
    video_file = create(:shared_file, :video)
    get download_preview_path(hash: video_file.download_hash)
    assert_response :success
    assert_equal "video/mp4", response.content_type
    assert_match "inline", response.headers["Content-Disposition"]
  end

  test "preview serves audio inline" do
    audio_file = create(:shared_file, :audio)
    get download_preview_path(hash: audio_file.download_hash)
    assert_response :success
    assert_equal "audio/mpeg", response.content_type
    assert_match "inline", response.headers["Content-Disposition"]
  end

  test "preview does not increment download counter" do
    image_file = create(:shared_file, :image)
    assert_no_difference -> { image_file.reload.download_count } do
      get download_preview_path(hash: image_file.download_hash)
    end
  end

  test "preview returns 404 for non-previewable file" do
    get download_preview_path(hash: @shared_file.download_hash)
    assert_response :not_found
  end

  test "preview returns 404 for invalid hash" do
    get download_preview_path(hash: "nonexistent_hash")
    assert_response :not_found
  end

  test "preview returns 410 for expired file" do
    expired_image = create(:shared_file, :image, :expired)
    get download_preview_path(hash: expired_image.download_hash)
    assert_response :gone
  end

  test "preview returns 410 for banned user's file" do
    image_file = create(:shared_file, :image)
    image_file.user.ban!
    get download_preview_path(hash: image_file.download_hash)
    assert_response :gone
  end
end
