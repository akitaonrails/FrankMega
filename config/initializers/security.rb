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
end
