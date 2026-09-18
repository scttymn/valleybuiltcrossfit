module Admin
  module Settings
    # The connection to PushPress, which the class schedule reads from.
    class PushpressController < BaseController
      FIELDS = [
        ResourcesController::Field[:pushpress_subdomain, hint: "e.g. valleybuiltcrossfit for valleybuiltcrossfit.pushpress.com"],
        ResourcesController::Field[:class_capacity, :number, hint: "Spots per class, used to show how many are open."],
        ResourcesController::Field[:uncapped_class_types, hint: "Comma-separated PushPress class types with no cap, e.g. General"]
      ].freeze

      self.fields = FIELDS.map(&:name)
    end
  end
end
