class DownloadsController < ApplicationController
  PREVIEW_CLAIM_TTL = 5.minutes
  PREVIEW_CLAIM_LIMIT = 20

  allow_unauthenticated_access

  before_action :find_shared_file
  before_action :check_owner_not_banned

  def show
    if @shared_file.nil?
      record_invalid_access
      render "not_found", status: :not_found
    elsif !@shared_file.active?
      render "expired", status: :gone
    end
  end

  def file
    if @shared_file.nil?
      record_invalid_access
      render "not_found", status: :not_found
    elsif !@shared_file.increment_download!
      render "expired", status: :gone
    else
      @shared_file.reload
      DownloadNotificationJob.perform_later(@shared_file.id)
      send_file ActiveStorage::Blob.service.path_for(@shared_file.file.key),
                filename: @shared_file.original_filename,
                type: @shared_file.content_type,
                disposition: "attachment"
    end
  end

  def preview
    if @shared_file.nil?
      record_invalid_access
      render plain: "", status: :not_found
    elsif @shared_file.expires_at <= Time.current
      render "expired", status: :gone
    elsif !@shared_file.previewable?
      render plain: "", status: :not_found
    elsif !preview_claimed? && !@shared_file.increment_download!
      render "expired", status: :gone
    else
      record_preview_claim! unless preview_claimed?
      send_file ActiveStorage::Blob.service.path_for(@shared_file.file.key),
                filename: @shared_file.original_filename,
                type: @shared_file.content_type,
                disposition: "inline"
    end
  end

  private

  def find_shared_file
    @shared_file = SharedFile.includes(:user).find_by(download_hash: params[:hash])
  end

  def check_owner_not_banned
    return if @shared_file.nil?

    render "expired", status: :gone if @shared_file.user.banned?
  end

  def record_invalid_access
    InvalidHashAccessJob.perform_later(request.remote_ip)
  end

  def preview_claimed?
    preview_claims.key?(@shared_file.download_hash)
  end

  def record_preview_claim!
    claims = preview_claims
    claims.shift while claims.size >= PREVIEW_CLAIM_LIMIT
    claims[@shared_file.download_hash] = Time.current.to_i
    session[:preview_claims] = claims
  end

  def preview_claims
    cutoff = (Time.current - PREVIEW_CLAIM_TTL).to_i
    claims = session[:preview_claims].to_h
    claims.select! { |_hash, claimed_at| claimed_at.to_i > cutoff }
    claims.shift while claims.size > PREVIEW_CLAIM_LIMIT
    session[:preview_claims] = claims
    claims
  end
end
