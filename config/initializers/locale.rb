# frozen_string_literal: true

# Set application locale from APP_LOCALE env var.
# This is a single-instance self-hosted app — locale is global, not per-user.
#
# We read from config.i18n (not I18n directly) because Rails hasn't yet
# applied config.i18n settings to the I18n module at initializer load time.
locale = ENV.fetch("APP_LOCALE", "en")
available = Rails.application.config.i18n.available_locales.map(&:to_s)
if available.include?(locale)
  Rails.application.config.i18n.default_locale = locale.to_sym
end
