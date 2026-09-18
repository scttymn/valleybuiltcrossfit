module Admin
  class ProgramsController < ResourcesController
    Field = ResourcesController::Field
    self.model = Program
    self.title = "Programs"
    self.sortable = true
    self.columns = %i[name blurb]
    self.fields = [
      Field[:name], Field[:blurb, :text, hint: "Short text on the program card."], Field[:photo, :file],
      Field[:what_title], Field[:what, :text], Field[:why_title], Field[:why, :text],
      Field[:kicker, hint: "Optional script-font line, e.g. \"Train hard. Recover well.\""],
      Field[:cta, :select, hint: "Button shown under the description.", options: Program::CTAS.invert.to_a],
      Field[:key, hint: "URL-safe id. Leave blank to generate from the name."], Field[:position, :number]
    ]
  end
end
