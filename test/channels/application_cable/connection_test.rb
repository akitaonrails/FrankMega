require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "accepts a current session" do
      user = create(:user)
      login = create(:session, user: user)
      cookies.signed[:session_id] = login.id

      connect

      assert_equal user, connection.current_user
    end

    test "rejects an expired session" do
      login = create(:session, expires_at: 1.minute.ago)
      cookies.signed[:session_id] = login.id

      assert_reject_connection { connect }
    end

    test "rejects a banned user" do
      login = create(:session, user: create(:user, :banned))
      cookies.signed[:session_id] = login.id

      assert_reject_connection { connect }
    end

    test "rejects a missing session" do
      assert_reject_connection { connect }
    end
  end
end
