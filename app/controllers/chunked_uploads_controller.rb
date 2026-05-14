class ChunkedUploadsController < ApplicationController
  def start
    upload = ChunkedUploadStore.create!(
      user: current_user,
      filename: params[:filename],
      byte_size: params[:byte_size],
      content_type: params[:content_type],
      shared_file_params: upload_params
    )

    render json: {
      upload_id: upload.id,
      chunk_size: ChunkedUploadStore.chunk_size,
      total_chunks: upload.metadata.fetch("total_chunks")
    }, status: :created
  rescue ChunkedUploadStore::Error => e
    render json: { errors: [ e.message ] }, status: :unprocessable_entity
  end

  def chunk
    upload = ChunkedUploadStore.find!(params[:id], user: current_user)
    upload.write_chunk!(index: params[:index], upload: params[:chunk])

    render json: { ok: true }
  rescue ChunkedUploadStore::Error => e
    render json: { errors: [ e.message ] }, status: :unprocessable_entity
  end

  def complete
    upload = ChunkedUploadStore.find!(params[:id], user: current_user)
    shared_file = upload.complete!(user: current_user)

    if shared_file.persisted?
      render json: { redirect_url: upload_path(shared_file) }, status: :created
    else
      render json: { errors: shared_file.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ChunkedUploadStore::Error => e
    render json: { errors: [ e.message ] }, status: :unprocessable_entity
  end

  private

  def upload_params
    params.require(:shared_file).permit(:max_downloads, :ttl_hours)
  end
end
