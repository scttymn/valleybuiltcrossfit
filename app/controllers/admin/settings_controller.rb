module Admin
  # Technical bits: how photos are processed for the site.
  class SettingsController < BaseController
    before_action { @site = Site.instance }

    def edit; end

    def update
      if @site.update(params.expect(site: [ :image_quality ]))
        redirect_to edit_admin_settings_path, notice: "Settings saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
