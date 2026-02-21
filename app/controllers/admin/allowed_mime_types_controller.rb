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
        redirect_to admin_allowed_mime_types_path, notice: "MIME type added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      AllowedMimeType.find(params[:id]).destroy
      redirect_to admin_allowed_mime_types_path, notice: "MIME type removed."
    end

    private

    def mime_type_params
      params.require(:allowed_mime_type).permit(:mime_type, :description, :enabled)
    end
  end
end
