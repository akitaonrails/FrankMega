Rails.application.config.x.security = ActiveSupport::OrderedOptions.new.tap do |config|
  if Rails.env.production?
    config.rate_limit_multiplier = 1
    config.ban_duration = 1.hour
    config.enable_banning = true
    config.max_invalid_hash_attempts = 3
    config.max_404_attempts = 3
  else
    config.rate_limit_multiplier = 10
    config.ban_duration = 1.minute
    config.enable_banning = false
    config.max_invalid_hash_attempts = 10
    config.max_404_attempts = 10
  end

  config.default_disk_quota_bytes = ENV.fetch("USER_DISK_QUOTA_BYTES", 5.gigabytes.to_s).to_i
  config.disk_quota_grace_bytes = 100.megabytes
end
