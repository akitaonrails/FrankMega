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
  end

  test "returns 410 for expired file" do
    expired = create(:shared_file, :expired)
    get download_path(hash: expired.download_hash)
    assert_response :gone
  end

  test "returns 410 for exhausted downloads" do
    exhausted = create(:shared_file, :exhausted)
    get download_path(hash: exhausted.download_hash)
    assert_response :gone
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
end
