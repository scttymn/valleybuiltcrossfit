module Admin
  class MembershipOptionsController < ResourcesController
    Field = ResourcesController::Field
    self.model = MembershipOption
    self.title = "Membership options"
    self.sortable = true
    self.columns = %i[name description]
    self.fields = [ Field[:name], Field[:description, hint: %(Links allowed, e.g. <a href="#dropin">See drop-in details</a>)], Field[:position, :number] ]
  end
end
