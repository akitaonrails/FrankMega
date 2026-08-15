# Rack::Attack needs an independent, in-process store: the deployment runs one Puma
# process behind Thruster, and MemoryStore counters are atomic under the GVL and do
# not fail open because of SQLite lock timeouts. Keep Rails.cache for application jobs.
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new(size: 32.megabytes)

security = Rails.application.config.x.security
multiplier = security.rate_limit_multiplier || 1

# Blocklist banned IPs (cached — see Ban.banned?)
Rack::Attack.blocklist("banned IPs") do |req|
  Ban.banned?(req.ip) if security.enable_banning
end

# Throttle login attempts by IP
Rack::Attack.throttle("logins/ip", limit: (5 * multiplier), period: 1.minute) do |req|
  req.ip if req.path == "/session" && req.post?
end

# Throttle login attempts by email
Rack::Attack.throttle("logins/email", limit: (5 * multiplier), period: 1.minute) do |req|
  if req.path == "/session" && req.post?
    req.params.dig("email_address")&.to_s&.downcase&.strip
  end
end

# Throttle 2FA OTP attempts by IP
Rack::Attack.throttle("2fa/ip", limit: (5 * multiplier), period: 1.minute) do |req|
  req.ip if req.path == "/two_factor_session" && req.post?
end

# Throttle WebAuthn authentication attempts by IP
Rack::Attack.throttle("webauthn/ip", limit: (5 * multiplier), period: 1.minute) do |req|
  req.ip if req.path == "/webauthn/session" && req.post?
end

# Throttle password reset requests by IP
Rack::Attack.throttle("password_resets/ip", limit: (5 * multiplier), period: 1.minute) do |req|
  req.ip if req.path == "/passwords" && req.post?
end

# Throttle download page views (GET) by IP
Rack::Attack.throttle("downloads_get/ip", limit: (60 * multiplier), period: 1.minute) do |req|
  req.ip if req.path.start_with?("/d/") && req.get?
end

# Throttle download attempts (POST) by IP
Rack::Attack.throttle("downloads/ip", limit: (30 * multiplier), period: 1.minute) do |req|
  req.ip if req.path.start_with?("/d/") && req.post?
end

# Throttle registration attempts by IP
Rack::Attack.throttle("registrations/ip", limit: (5 * multiplier), period: 1.minute) do |req|
  req.ip if req.path.start_with?("/register/") && req.post?
end

# Throttle general requests
Rack::Attack.throttle("requests/ip", limit: (300 * multiplier), period: 5.minutes) do |req|
  req.ip unless req.path.start_with?("/assets")
end

# Custom response for throttled requests
Rack::Attack.throttled_responder = lambda do |_req|
  [ 429, { "Content-Type" => "text/plain" }, [ "Rate limit exceeded. Try again later.\n" ] ]
end

# Custom response for blocked requests
Rack::Attack.blocklisted_responder = lambda do |_req|
  [ 403, { "Content-Type" => "text/plain" }, [ "Forbidden.\n" ] ]
end
