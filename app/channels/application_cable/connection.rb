module ApplicationCable
  class Connection < ActionCable::Connection::Base
    AUTH_CHECK_INTERVAL = 30.seconds

    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    def beat
      if Time.current >= @next_auth_check
        session = Session.includes(:user).find_by(id: @session_id)
        unless valid_session?(session)
          close(reason: ActionCable::INTERNAL[:disconnect_reasons][:unauthorized], reconnect: false)
          return
        end

        @next_auth_check = [ Time.current + AUTH_CHECK_INTERVAL, session.expires_at ].min
      end

      super
    end

    private
      def set_current_user
        session = Session.includes(:user).find_by(id: cookies.signed[:session_id])
        if valid_session?(session)
          @session_id = session.id
          @next_auth_check = [ Time.current + AUTH_CHECK_INTERVAL, session.expires_at ].min
          self.current_user = session.user
        end
      end

      def valid_session?(session)
        session && session.expires_at > Time.current && !session.user.banned?
      end
  end
end
