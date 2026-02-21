class InvalidHashAccessJob < ApplicationJob
  queue_as :default

  def perform(ip_address)
    security = Rails.application.config.x.security
    return unless security.enable_banning

    cache_key = "invalid_hash:#{ip_address}"
    count = Rails.cache.increment(cache_key, 1, expires_in: 1.hour) || 1

    if count >= security.max_invalid_hash_attempts
      Ban.ban!(ip_address, reason: "Repeated invalid download hash access", duration: security.ban_duration)
      Rails.cache.delete(cache_key)
    end
  end
end
