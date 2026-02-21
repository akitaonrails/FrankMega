WebAuthn.configure do |config|
  config.allowed_origins = [ ENV.fetch("WEBAUTHN_ORIGIN") { "http://localhost:3000" } ]
  config.rp_name = "FrankMega"
  config.rp_id = ENV.fetch("WEBAUTHN_RP_ID") { "localhost" }
end
