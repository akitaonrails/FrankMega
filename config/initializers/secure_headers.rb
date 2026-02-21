SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true,
    httponly: true,
    samesite: { lax: true }
  }

  config.hsts = "max-age=#{1.year.to_i}; includeSubDomains"
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = %w[strict-origin-when-cross-origin]

  # CSP is handled by Rails built-in (config/initializers/content_security_policy.rb)
  # which supports nonces for importmap inline scripts.
  config.csp = SecureHeaders::OPT_OUT
end
