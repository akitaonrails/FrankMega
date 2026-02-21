WebAuthn.configure do |config|
  if Rails.env.production?
    config.allowed_origins = [ ENV.fetch("WEBAUTHN_ORIGIN") ]
    config.rp_id = ENV.fetch("WEBAUTHN_RP_ID")
  else
    config.allowed_origins = [ ENV.fetch("WEBAUTHN_ORIGIN", "http://localhost:3000") ]
    config.rp_id = ENV.fetch("WEBAUTHN_RP_ID", "localhost")
  end
  config.rp_name = "FrankMega"
end
