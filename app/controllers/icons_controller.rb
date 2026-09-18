# The favicon: the logo mark filled with the saved accent color. A browser tab
# can't use the site's stylesheet, so the color goes into the file itself.
# Pages link it with a version of the color and the drawing.
class IconsController < ActionController::Base
  FAVICON = Rails.root.join("app/assets/images/logo-favicon.svg")

  # The accent and a fingerprint of the drawing: a new color or a new drawing
  # is a new URL, so the long cache never serves a stale icon.
  def self.version(accent) = "#{accent.delete("#")}-#{drawing_digest}"

  def self.drawing_digest
    return Digest::SHA256.file(FAVICON).hexdigest.first(8) unless Rails.configuration.cache_classes
    @drawing_digest ||= Digest::SHA256.file(FAVICON).hexdigest.first(8)
  end

  def favicon
    accent = Site.instance.theme.accent
    if params[:v] == self.class.version(accent)
      expires_in 1.year, public: true
    else
      expires_in 5.minutes, public: true
    end

    svg = Nokogiri::XML(FAVICON.read)
    svg.at_css("g.logo-mark")["fill"] = accent
    render plain: svg.root.to_xml, content_type: "image/svg+xml"
  end
end
