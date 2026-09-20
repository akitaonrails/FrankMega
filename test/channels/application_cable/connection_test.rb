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

    test "disconnects when an active session expires" do
      login = create(:session, expires_at: 1.minute.from_now)
      cookies.signed[:session_id] = login.id
      connect

      travel 2.minutes do
        assert_connection_closed
      end
    end

    test "disconnects when an active session is revoked" do
      login = create(:session)
      cookies.signed[:session_id] = login.id
      connect
      login.destroy!

      travel 31.seconds do
        assert_connection_closed
      end
    end

    test "disconnects when an active user becomes banned" do
      login = create(:session)
      cookies.signed[:session_id] = login.id
      connect
      login.user.update!(banned: true)

      travel 31.seconds do
        assert_connection_closed
      end
    end

    test "keeps an active session connected after revalidation" do
      login = create(:session)
      cookies.signed[:session_id] = login.id
      connect
      pinged = false
      connection.define_singleton_method(:transmit) { |_message| pinged = true }

      travel 31.seconds do
        connection.beat
      end

      assert pinged
    end

    private

    def assert_connection_closed
      closed = false
      connection.define_singleton_method(:close) { |**options| closed = options[:reconnect] == false }
      connection.define_singleton_method(:transmit) { |_message| }
      connection.beat
      assert closed
    end
  end
end
