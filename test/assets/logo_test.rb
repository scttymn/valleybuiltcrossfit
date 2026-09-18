require "test_helper"

# The logo has to sit on whatever background the theme sets. It used to carry a
# solid black box, hidden with mix-blend-mode: screen — which only hides black on
# a dark page, and lightens the logo's own colors on anything but pure black.
class LogoTest < ActiveSupport::TestCase
  LOGO = Rails.root.join("app/assets/images/logo-valley-built-horizontal.png")
  BRAND = { green: [ 96, 114, 72 ], cream: [ 211, 199, 183 ] }.freeze

  setup { @logo = Vips::Image.new_from_file(LOGO.to_s) }

  test "the logo has a transparent background" do
    assert_equal 4, @logo.bands, "no alpha channel"

    corners = [ [ 0, 0 ], [ @logo.width - 1, 0 ], [ 0, @logo.height - 1 ], [ @logo.width - 1, @logo.height - 1 ] ]
    corners.each { |x, y| assert_equal 0, @logo.getpoint(x, y).last, "corner #{x},#{y} is not transparent" }
  end

  test "the brand colors are solid, not faded by the transparency" do
    colors = @logo.bandsplit.then { |r, g, b, a| [ r, g, b, a ] }
    BRAND.each do |name, (r, g, b)|
      solid = (colors[0] == r) & (colors[1] == g) & (colors[2] == b) & (colors[3] == 255)
      assert_operator solid.avg, :>, 0.01, "no fully opaque #{name} in the logo"
    end
  end

  test "no stylesheet blends the logo into the page" do
    # Blending is allowed on photo layers (the theme's photo style) and
    # nowhere else — and the logo is never a photo.
    Rails.root.glob("app/assets/stylesheets/*.css").each do |sheet|
      sheet.read.gsub(%r{/\*.*?\*/}m, "").scan(/([^{}]+)\{([^}]*)\}/).each do |selector, body|
        next unless body.include?("mix-blend-mode")
        assert_match(/\A\s*\.photo:has\(img\):not\(\.photo--broken\)::after\s*\z/, selector, "#{sheet.basename}: #{selector.strip} blends — only photo layers may")
      end
    end
  end
end
