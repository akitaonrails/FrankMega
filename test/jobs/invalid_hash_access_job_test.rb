require "test_helper"

class InvalidHashAccessJobTest < ActiveJob::TestCase
  test "does not ban when banning is disabled" do
    assert_no_difference "Ban.count" do
      10.times { InvalidHashAccessJob.perform_now("5.5.5.5") }
    end
  end
end
