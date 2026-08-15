class SetupController < ApplicationController
  allow_unauthenticated_access

  before_action :ensure_no_users

  def new
    @user = User.new
    @setup_token_configured = ENV["SETUP_TOKEN"].present?
  end

  def create
    @user = User.new(user_params)
    @setup_token_configured = ENV["SETUP_TOKEN"].present?
    @user.role = "admin"
    @user.skip_terms_validation = true

    if valid_setup_token? && @user.valid?
      User.transaction(requires_new: true) do
        raise ActiveRecord::RecordNotUnique unless User.count.zero?

        @user.save!
      end
      start_new_session_for @user
      redirect_to root_path, notice: t("flash.setup.create.notice")
    else
      @user.errors.add(:base, t("flash.setup.create.token_required"))
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid
    redirect_to root_path
  end

  private

  def ensure_no_users
    redirect_to root_path unless User.count.zero?
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  def valid_setup_token?
    configured_token = ENV["SETUP_TOKEN"]
    configured_token.present? && params[:setup_token].present? &&
      ActiveSupport::SecurityUtils.secure_compare(configured_token, params[:setup_token])
  end
end
