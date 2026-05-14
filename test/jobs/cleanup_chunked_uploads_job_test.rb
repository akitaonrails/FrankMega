require "test_helper"

class CleanupChunkedUploadsJobTest < ActiveJob::TestCase
  teardown do
    FileUtils.rm_rf(ChunkedUploadStore.root)
  end

  test "removes expired chunked upload sessions" do
    user = create(:user)
    upload = ChunkedUploadStore.create!(
      user: user,
      filename: "old.txt",
      byte_size: 10,
      content_type: "text/plain",
      shared_file_params: { max_downloads: 5, ttl_hours: 12 }
    )
    metadata_path = ChunkedUploadStore.root.join(upload.id, "metadata.json")
    metadata = JSON.parse(metadata_path.read)
    metadata["created_at"] = 7.hours.ago.iso8601
    metadata_path.write(JSON.generate(metadata))

    CleanupChunkedUploadsJob.perform_now

    assert_not ChunkedUploadStore.root.join(upload.id).exist?
  end

  test "keeps fresh chunked upload sessions" do
    user = create(:user)
    upload = ChunkedUploadStore.create!(
      user: user,
      filename: "fresh.txt",
      byte_size: 10,
      content_type: "text/plain",
      shared_file_params: { max_downloads: 5, ttl_hours: 12 }
    )

    CleanupChunkedUploadsJob.perform_now

    assert ChunkedUploadStore.root.join(upload.id).exist?
  end
end
