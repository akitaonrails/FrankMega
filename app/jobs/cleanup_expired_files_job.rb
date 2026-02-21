class CleanupExpiredFilesJob < ApplicationJob
  queue_as :default

  def perform
    SharedFile.inactive.find_each do |shared_file|
      shared_file.file.purge if shared_file.file.attached?
      shared_file.destroy
    end
  end
end
