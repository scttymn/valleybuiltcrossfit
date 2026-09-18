module Admin
  class SitesController < BaseController
    Field = ResourcesController::Field

    SECTIONS = {
      "Contact" => [
        Field[:phone], Field[:email], Field[:instagram_url], Field[:address_line1], Field[:address_line2], Field[:city_state_zip],
        Field[:lead_notification_email, hint: "Where \"Get your options\" form submissions are emailed. Defaults to the email above."]
      ],
      "Hero" => [
        Field[:hero_eyebrow], Field[:hero_title], Field[:hero_title_accent, hint: "Second line, in green."], Field[:hero_body, :text],
        Field[:hero_tags, hint: "Separate with /"], Field[:hero_photo, :file]
      ],
      "Programs, steps & schedule" => [
        Field[:programs_intro], Field[:steps_eyebrow], Field[:steps_title], Field[:schedule_intro]
      ],
      "Drop-in" => [
        Field[:dropin_title], Field[:dropin_body, :text], Field[:dropin_why_title], Field[:dropin_why_body, :text],
        Field[:dropin_price], Field[:dropin_price_note], Field[:dropin_url, hint: "PushPress drop-in plan link."]
      ],
      "Membership" => [
        Field[:membership_title, :text], Field[:membership_body, :text], Field[:membership_rate_note]
      ],
      "Find us" => [ Field[:visit_title], Field[:visit_script, hint: "Script-font line under the title."] ],
      "PushPress" => [
        Field[:pushpress_subdomain, hint: "e.g. valleybuiltcrossfit for valleybuiltcrossfit.pushpress.com"],
        Field[:class_capacity, :number, hint: "Spots per class, used to show how many are open."],
        Field[:uncapped_class_types, hint: "Comma-separated PushPress class types with no cap, e.g. General"]
      ]
    }.freeze

    before_action { @site = Site.instance }

    def edit; end

    def update
      fields = SECTIONS.values.flatten
      attrs = params.expect(site: fields.map(&:name))
      fields.select { _1.type == :file }.each do |field|
        attrs.delete(field.name) if attrs[field.name].blank?
        @site.public_send(field.name).purge_later if params.dig(:site, "remove_#{field.name}") == "1"
      end

      if @site.update(attrs)
        redirect_to edit_admin_site_path, notice: "Site content saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
