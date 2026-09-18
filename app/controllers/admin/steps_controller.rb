module Admin
  class StepsController < ResourcesController
    Field = ResourcesController::Field
    self.model = Step
    self.title = "What to expect steps"
    self.sortable = true
    self.columns = %i[title body]
    self.fields = [ Field[:title], Field[:body, :text], Field[:position, :number] ]
  end
end
