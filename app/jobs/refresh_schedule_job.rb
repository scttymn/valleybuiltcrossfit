class RefreshScheduleJob < ApplicationJob
  queue_as :default

  def perform(weeks: 3)
    weeks.times { |offset| Schedule.for_offset(offset).refresh! }
  end
end
