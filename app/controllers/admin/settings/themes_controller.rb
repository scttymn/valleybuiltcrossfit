module Admin
  module Settings
    # The site's three colors, and the sample drawn beside the pickers.
    class ThemesController < BaseController
      self.fields = [ *Site::THEME_COLORS.values, :theme_border_width, :theme_photo_style ]

      # Pieces of the real site in the colors being tried, with the real
      # stylesheet and the real Theme. Never saves.
      def preview
        @theme = @site.theme.with(**params.permit(*Theme::DEFAULTS.keys, :border_width, :photo_style).to_h.symbolize_keys)
        # Real site photos — the dark hero and a bright program shot — so the
        # photo style can be judged on the kind of photo it changes most.
        @sample_photos = [ @site.hero_photo, Program.ordered.map(&:photo).find(&:attached?) ].compact.select(&:attached?)
        render layout: "application"
      end

      private
        def settings_params = params[:reset_colors] ? fields.index_with(nil) : super
        def saved_notice = params[:reset_colors] ? "Colors reset to the defaults." : "Theme saved."
    end
  end
end
