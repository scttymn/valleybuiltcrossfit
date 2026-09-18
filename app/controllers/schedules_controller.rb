class SchedulesController < ApplicationController
  allow_unauthenticated_access

  def show
    @week = params[:week].to_i.clamp(0, 52)
    @schedule = Schedule.for_offset(@week)
    # Warm what they're likely to open next, so paging ahead stays instant even
    # past the window the refresh job maintains.
    Schedule.prefetch_ahead(@week)
    render partial: "schedules/schedule", locals: { schedule: @schedule, week: @week }
  end
end
