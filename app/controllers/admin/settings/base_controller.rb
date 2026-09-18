module Admin
  module Settings
    # One focused page per group of site-wide settings. Each saves only the
    # fields it declares, so no page can overwrite another's.
    class BaseController < Admin::BaseController
      class_attribute :fields, default: []

      before_action { @site = Site.instance }

      def edit; end

      def update
        if @site.update(settings_params)
          redirect_to({ action: :edit }, notice: saved_notice)
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private
        def settings_params = params.expect(site: fields)
        def saved_notice = "Saved."
    end
  end
end
