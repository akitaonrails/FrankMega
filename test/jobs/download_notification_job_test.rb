require "test_helper"

class DownloadNotificationJobTest < ActiveJob::TestCase
  test "does not raise for valid shared file" do
    shared_file = create(:shared_file)
    assert_nothing_raised do
      DownloadNotificationJob.perform_now(shared_file.id)
    end
  end

  test "silently returns for nonexistent shared file" do
    assert_nothing_raised do
      DownloadNotificationJob.perform_now(-1)
    end
  end
end
