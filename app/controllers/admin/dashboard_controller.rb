module Admin
  class DashboardController < BaseController
    def show
      @recent_leads = Lead.order(created_at: :desc).limit(5)
      @schedule = Schedule.for_offset(0)
      @missing_workouts = @schedule.dates.to_a - Workout.where(date: @schedule.dates).pluck(:date)
    end

    def refresh_schedule
      RefreshScheduleJob.perform_now
      redirect_to admin_root_path, notice: "Schedule refreshed from PushPress."
    rescue Pushpress::Client::Error, SocketError, Timeout::Error, SystemCallError => e
      redirect_to admin_root_path, alert: "Couldn't reach PushPress: #{e.message}"
    end
  end
end
