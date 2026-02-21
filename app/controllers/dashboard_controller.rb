class DashboardController < ApplicationController
  def index
    @shared_files = current_user.shared_files.order(created_at: :desc)
    @active_files = @shared_files.active
    @inactive_files = @shared_files.inactive
  end
end
