class SchedulesController < ApplicationController
  allow_unauthenticated_access

  def show
    @week = params[:week].to_i.clamp(0, 52)
    @schedule = Schedule.for_offset(@week)
    render partial: "schedules/schedule", locals: { schedule: @schedule, week: @week }
  end
end
