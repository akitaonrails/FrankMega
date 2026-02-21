class CleanupExpiredBansJob < ApplicationJob
  queue_as :default

  def perform
    Ban.expired.delete_all
  end
end
