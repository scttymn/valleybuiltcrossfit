module Admin
  class PillarsController < ResourcesController
    Field = ResourcesController::Field
    self.model = Pillar
    self.title = "Pillars"
    self.sortable = true
    self.columns = %i[title body]
    self.fields = [ Field[:title], Field[:body], Field[:position, :number] ]
  end
end
