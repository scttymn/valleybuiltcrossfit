# Keeps the cached schedule warm so a page view never waits on PushPress.
#
# The calendar itself is one cheap request however wide the window, but every
# class needs its own request for its reservation count, so a two-month sweep is
# ~200 calls. Spots left only moves for classes people can book soon, so the
# near weeks refresh often and the rest of the horizon rides a slower pass.
# Schedule.prefetch_ahead uses this too, to warm the weeks past the horizon as
# someone pages into them.
class RefreshScheduleJob < ApplicationJob
  queue_as :default

  NEAR_WEEKS = 3

  def perform(weeks: NEAR_WEEKS, starting: 0)
    Schedule.refresh!(weeks:, starting:)
  end
end
