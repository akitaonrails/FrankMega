class CleanupChunkedUploadsJob < ApplicationJob
  queue_as :default

  def perform
    ChunkedUploadStore.prune_expired!
  end
end
