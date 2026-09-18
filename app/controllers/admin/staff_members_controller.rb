module Admin
  class StaffMembersController < ResourcesController
    Field = ResourcesController::Field
    self.model = StaffMember
    self.title = "Staff"
    self.sortable = true
    self.columns = %i[name kind role certification]
    self.fields = [
      Field[:name, hint: "For the owners card this can be both names, e.g. \"Jessica & Greg Isaacson\""],
      Field[:kind, :select, hint: "Owners show in the wide card at the top of the section; coaches in the grid below.", options: StaffMember::KINDS.invert.to_a],
      Field[:role, hint: "e.g. Head coach, Coach, Owners"],
      Field[:certification, hint: "e.g. CF-L1"],
      Field[:certification_label, hint: "Optional text before the certification, e.g. \"Jessica coaches\""],
      Field[:bio, :text], Field[:photo, :file], Field[:position, :number]
    ]
  end
end
