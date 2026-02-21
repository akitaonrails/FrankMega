module Admin
  class InvitationsController < Admin::ApplicationController
    def index
      @invitations = Invitation.includes(:used_by).order(created_at: :desc)
    end

    def new
      @invitation = Invitation.new
    end

    def create
      @invitation = Invitation.new(
        created_by: current_user,
        expires_at: params.dig(:invitation, :expires_at) || 7.days.from_now
      )

      if @invitation.save
        flash[:notice] = t("flash.admin.invitations.create.notice")
        flash[:invitation_url] = register_url(code: @invitation.code)
        redirect_to admin_invitations_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      invitation = Invitation.find(params[:id])
      invitation.destroy
      redirect_to admin_invitations_path, notice: t("flash.admin.invitations.destroy.notice")
    end
  end
end
