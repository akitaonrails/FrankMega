class DownloadNotificationJob < ApplicationJob
  queue_as :default

  def perform(shared_file_id)
    shared_file = SharedFile.find_by(id: shared_file_id)
    return unless shared_file

    Turbo::StreamsChannel.broadcast_update_to(
      "user_#{shared_file.user_id}_notifications",
      target: "shared_file_#{shared_file.id}",
      partial: "uploads/shared_file",
      locals: { shared_file: shared_file }
    )

    Turbo::StreamsChannel.broadcast_append_to(
      "user_#{shared_file.user_id}_notifications",
      target: "toast_notifications",
      partial: "shared/download_toast",
      locals: { shared_file: shared_file }
    )
  end
end
