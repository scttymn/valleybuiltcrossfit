# The pages in public/ are written once and can't know the theme, so error
# responses are rendered here instead (config.exceptions_app): same fonts,
# colors and logo as the rest of the site, following a theme change with it.
#
# ActionDispatch hands the failed request back to the router with the status
# code as the path ("/404"), and the route passes it on as params[:status].
class ErrorsController < ApplicationController
  allow_unauthenticated_access

  PAGES = {
    "404" => [ "Page not found", "That link doesn't lead anywhere. It may have moved, or the address may have a typo in it." ],
    "422" => [ "That didn't go through", "The form was rejected — usually because the page sat open too long. Head back and send it again." ],
    "500" => [ "Something broke", "That's on us, not on you. Try again in a minute; if it keeps happening, give us a call." ]
  }.freeze

  def show
    @status = PAGES.key?(params[:status]) ? params[:status] : "500"
    @heading, @message = PAGES[@status]
    @site = Site.instance

    respond_to do |format|
      format.html { render :show, status: @status.to_i }
      # Anything that isn't a page — a stray image, a script, a probe for
      # /wp-login.php — only needs the status.
      format.any { head @status.to_i }
    end
  rescue StandardError => e
    # The app is already failing; don't fail again inside the page that says so.
    Rails.logger.error("[Errors] #{e.class}: #{e.message}")
    render "errors/fallback", status: :internal_server_error, layout: false
  end
end
