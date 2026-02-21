module Admin
  class ApplicationController < ::ApplicationController
    before_action :require_admin

    private

    def require_admin
      unless current_user&.admin?
        redirect_to root_path, alert: "Not authorized."
      end
    end
  end
end
