# Redact capability-bearing paths before they are written to application logs.
# production.rb loads this before initializers; Rails later evaluates it again.
unless defined?(RedactingLogFormatter)
  class RedactingLogFormatter < ActiveSupport::Logger::SimpleFormatter
    CAPABILITY_PATHS = {
      %r{/d/[A-Za-z0-9_-]+} => "/d/[REDACTED]",
      %r{/passwords/[A-Za-z0-9_-]+} => "/passwords/[REDACTED]",
      %r{/register/[A-Za-z0-9_-]+} => "/register/[REDACTED]"
    }.freeze

    def call(severity, timestamp, progname, message)
      CAPABILITY_PATHS.reduce(message.to_s) { |redacted, (pattern, replacement)| redacted.gsub(pattern, replacement) }
                      .then { |redacted| super(severity, timestamp, progname, redacted) }
    end
  end
end
