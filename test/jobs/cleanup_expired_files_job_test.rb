require "test_helper"

class CleanupExpiredFilesJobTest < ActiveJob::TestCase
  test "removes expired files" do
    expired = create(:shared_file, :expired)
    active = create(:shared_file)

    CleanupExpiredFilesJob.perform_now

    assert_not SharedFile.exists?(expired.id)
    assert SharedFile.exists?(active.id)
  end

  test "keeps exhausted files until they expire" do
    exhausted = create(:shared_file, :exhausted)
    active = create(:shared_file)

    CleanupExpiredFilesJob.perform_now

    assert SharedFile.exists?(exhausted.id)
    assert SharedFile.exists?(active.id)
  end
end
