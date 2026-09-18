module Admin
  module Settings
    # The connection to PushPress: the class schedule reads from it, and the
    # home page's chat is its Grow widget.
    class PushpressController < BaseController
      FIELDS = [
        ResourcesController::Field[:pushpress_subdomain, hint: "e.g. valleybuiltcrossfit for valleybuiltcrossfit.pushpress.com"],
        ResourcesController::Field[:class_capacity, :number, hint: "Spots per class, used to show how many are open."],
        ResourcesController::Field[:uncapped_class_types, hint: "Comma-separated PushPress class types with no cap, e.g. General"],
        ResourcesController::Field[:chat_widget_id, hint: "The \"Have a question?\" chat on the home page. In PushPress Grow: Sites → Chat Widget → the widget's embed code, the data-widget-id value. Leave blank for no chat."]
      ].freeze

      self.fields = FIELDS.map(&:name)
    end
  end
end
