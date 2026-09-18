module Admin
  class FaqsController < ResourcesController
    Field = ResourcesController::Field
    self.model = Faq
    self.title = "FAQs"
    self.sortable = true
    self.columns = %i[question answer]
    self.fields = [ Field[:question], Field[:answer, :text, hint: %(Links allowed, e.g. <a href="mailto:you@example.com">email us</a>)], Field[:position, :number] ]
  end
end
