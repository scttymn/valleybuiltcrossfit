module Admin
  # Technical bits: how photos are processed, and the site's colors.
  class SettingsController < BaseController
    before_action { @site = Site.instance }

    def edit; end

    def update
      attributes = params.expect(site: [ :image_quality, *Site::THEME_COLORS.values ])
      attributes = attributes.merge(Site::THEME_COLORS.values.index_with(nil)) if params[:reset_colors]

      if @site.update(attributes)
        redirect_to edit_admin_settings_path, notice: params[:reset_colors] ? "Colors reset to the defaults." : "Settings saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # The sample beside the color pickers: a few pieces of the real site, drawn
    # with the real stylesheet in the colors being tried. Never saves.
    def theme_preview
      @theme = @site.theme.with(**params.permit(*Theme::DEFAULTS.keys).to_h.symbolize_keys)
      render layout: "application"
    end
  end
end
