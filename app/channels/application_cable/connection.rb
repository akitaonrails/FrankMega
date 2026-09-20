module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        if (session = Session.includes(:user).find_by(id: cookies.signed[:session_id])) &&
            session.expires_at > Time.current && !session.user.banned?
          self.current_user = session.user
        end
      end
  end
end
