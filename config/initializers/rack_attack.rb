Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

security = Rails.application.config.x.security
multiplier = security.rate_limit_multiplier || 1

# Blocklist banned IPs
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

# Throttle download attempts by IP
Rack::Attack.throttle("downloads/ip", limit: (30 * multiplier), period: 1.minute) do |req|
  req.ip if req.path.start_with?("/d/") && req.post?
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
