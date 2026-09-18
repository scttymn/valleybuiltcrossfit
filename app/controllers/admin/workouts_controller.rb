module Admin
  class WorkoutsController < ResourcesController
    Field = ResourcesController::Field
    self.model = Workout
    self.title = "Workouts"
    self.columns = %i[date name workout_type]
    self.fields = [
      Field[:date, :date], Field[:name, hint: "Optional, e.g. Benchmark Friday"], Field[:workout_type, hint: "e.g. For time, AMRAP 20"],
      Field[:rx, :text, hint: "The workout, one movement per line. Leave blank for a rest day."],
      Field[:loads, :text, hint: "One line per standard, e.g. ♀ 95-lb barbell"],
      Field[:score, hint: "e.g. Post time to the whiteboard."], Field[:source, hint: "Optional credit line"],
      Field[:stimulus, :text], Field[:intermediate, :text], Field[:beginner, :text]
    ]

    def new
      @record = model.new(date: params.dig(:workout, :date).presence || (model.maximum(:date) || Date.current - 1) + 1)
      render "admin/resources/new"
    end
  end
end
