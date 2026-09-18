# The favicon: the logo mark filled with the saved accent color. A browser tab
# can't use the site's stylesheet, so the color goes into the file itself.
# Pages link it with the color as a version, so a new color is a new URL.
class IconsController < ActionController::Base
  FAVICON = Rails.root.join("app/assets/images/logo-favicon.svg")

  def favicon
    accent = Site.instance.theme.accent
    if params[:v] == accent.delete("#")
      expires_in 1.year, public: true
    else
      expires_in 5.minutes, public: true
    end

    svg = Nokogiri::XML(FAVICON.read)
    svg.at_css("g.logo-mark")["fill"] = accent
    render plain: svg.root.to_xml, content_type: "image/svg+xml"
  end
end
