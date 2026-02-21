require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FrankMega
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    config.time_zone = "UTC"

    # ActiveRecord encryption for sensitive fields (otp_secret)
    # Production MUST set these env vars — app will refuse to boot without them.
    # Dev/test use safe defaults that must never be used in production.
    if Rails.env.production?
      config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY")
      config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY")
      config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
    else
      config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", "dev-only-primary-key-32chars-long!")
      config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY", "dev-only-deterministic-key-32ch!")
      config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT", "dev-only-derivation-salt-32char!")
    end

    # I18n
    config.i18n.available_locales = [ :en, :"pt-BR" ]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true

    # Generators
    config.generators do |g|
      g.test_framework :minitest, fixture: false
      g.fixture_replacement :factory_bot, dir: "test/factories"
    end
  end
end
