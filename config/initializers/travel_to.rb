# Development only: start the server at another moment to see the site as it
# would look then (which day is today, which classes are over):
#
#   TRAVEL_TO="2026-10-07 12:00" bin/rails server
#
# The clock stands still at that moment (Time.now, Date.today, Time.current)
# until the server restarts. Read in the app's time zone.
if Rails.env.development? && ENV["TRAVEL_TO"].present?
  require "active_support/testing/time_helpers"

  Rails.application.config.after_initialize do
    moment = Time.zone.parse(ENV["TRAVEL_TO"]) or raise ArgumentError, "TRAVEL_TO=#{ENV["TRAVEL_TO"].inspect} isn't a time"
    Object.new.extend(ActiveSupport::Testing::TimeHelpers).travel_to(moment)
    Rails.logger.info("[travel_to] the clock is set to #{Time.current}")
    warn "=> TRAVEL_TO: the clock is set to #{Time.current}"
  end
end
