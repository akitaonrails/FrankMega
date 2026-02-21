module Admin
  class AllowedMimeTypesController < Admin::ApplicationController
    def index
      @mime_types = AllowedMimeType.order(:mime_type)
    end

    def new
      @mime_type = AllowedMimeType.new
    end

    def create
      @mime_type = AllowedMimeType.new(mime_type_params)

      if @mime_type.save
        redirect_to admin_allowed_mime_types_path, notice: t("flash.admin.allowed_mime_types.create.notice")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      AllowedMimeType.find(params[:id]).destroy
      redirect_to admin_allowed_mime_types_path, notice: t("flash.admin.allowed_mime_types.destroy.notice")
    end

    private

    def mime_type_params
      params.require(:allowed_mime_type).permit(:mime_type, :description, :enabled)
    end
  end
end
