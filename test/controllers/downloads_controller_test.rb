require "test_helper"

class DownloadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    %w[application/pdf image/png video/mp4 audio/mpeg].each do |mime_type|
      AllowedMimeType.find_or_create_by!(mime_type: mime_type) { |type| type.description = mime_type }
    end
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

  test "preview increments download counter" do
    image_file = create(:shared_file, :image)
    assert_difference -> { image_file.reload.download_count }, 1 do
      get download_preview_path(hash: image_file.download_hash)
    end
    assert_response :success
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

  test "second preview in the same session does not consume another download" do
    image_file = create(:shared_file, :image, max_downloads: 1)

    get download_preview_path(hash: image_file.download_hash)
    assert_response :success

    assert_no_difference -> { image_file.reload.download_count } do
      get download_preview_path(hash: image_file.download_hash)
    end
    assert_response :success
  end

  test "expired preview claim requires another download" do
    image_file = create(:shared_file, :image, max_downloads: 1)

    get download_preview_path(hash: image_file.download_hash)
    assert_response :success

    travel 6.minutes do
      get download_preview_path(hash: image_file.download_hash)
      assert_response :gone
    end
  end

  test "preview claims are scoped to each file hash" do
    first_file = create(:shared_file, :image, max_downloads: 1)
    second_file = create(:shared_file, :image, max_downloads: 1)

    assert_difference -> { first_file.reload.download_count }, 1 do
      get download_preview_path(hash: first_file.download_hash)
    end
    assert_difference -> { second_file.reload.download_count }, 1 do
      get download_preview_path(hash: second_file.download_hash)
    end
  end

  test "expired files return 410 even with a preview claim" do
    image_file = create(:shared_file, :image, max_downloads: 1)

    get download_preview_path(hash: image_file.download_hash)
    assert_response :success
    image_file.update!(expires_at: 1.minute.ago)

    get download_preview_path(hash: image_file.download_hash)
    assert_response :gone
  end

  test "preview returns 410 for banned user's file" do
    image_file = create(:shared_file, :image)
    image_file.user.ban!
    get download_preview_path(hash: image_file.download_hash)
    assert_response :gone
  end
end
