module Admin
  # The bar across the very top of the site: one line, optionally a link.
  class AnnouncementsController < BaseController
    before_action { @site = Site.instance }

    def edit; end

    def update
      if @site.update(params.expect(site: %i[announcement announcement_url announcement_visible]))
        redirect_to edit_admin_announcement_path, notice: "Announcement bar saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
