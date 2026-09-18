module Admin
  module Settings
    # The site's three colors, and the sample drawn beside the pickers.
    class ThemesController < BaseController
      self.fields = Site::THEME_COLORS.values

      # Pieces of the real site in the colors being tried, with the real
      # stylesheet and the real Theme. Never saves.
      def preview
        @theme = @site.theme.with(**params.permit(*Theme::DEFAULTS.keys).to_h.symbolize_keys)
        render layout: "application"
      end

      private
        def settings_params = params[:reset_colors] ? fields.index_with(nil) : super
        def saved_notice = params[:reset_colors] ? "Colors reset to the defaults." : "Theme saved."
    end
  end
end
