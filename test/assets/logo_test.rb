require "test_helper"

# The logo is an SVG drawn into the page, so the theme colors it: the mark and
# the CROSSFIT line in the accent, the name in the text color. It has no colors
# of its own, and nothing blends it into the background.
class LogoTest < ActiveSupport::TestCase
  LOGOS = ApplicationHelper::LOGOS

  test "each logo has its three parts and no colors of its own" do
    LOGOS.each do |layout, file|
      svg = Nokogiri::XML(file.read)
      assert_equal "svg", svg.root.name, layout
      assert_match(/\A[-\d.]+ [-\d.]+ [\d.]+ [\d.]+\z/, svg.root["viewBox"], layout)
      %w[logo-mark logo-name logo-tagline].each do |part|
        assert_equal 1, svg.css("g.#{part}").size, "#{layout}: no #{part}"
        assert_operator svg.css("g.#{part} path").size, :>=, 1, "#{layout}: #{part} is empty"
      end
      assert_empty svg.xpath("//*[@fill or @stroke or @style]"), "#{layout}: a color in the file would override the theme"
      assert_empty svg.xpath("//*[local-name()='script' or local-name()='image' or local-name()='foreignObject']"), layout
    end
  end

  test "the horizontal logo is wide and the stacked one is not" do
    width = ->(layout) { Nokogiri::XML(LOGOS[layout].read).root["viewBox"].split.map(&:to_f).then { _1[2] / _1[3] } }
    assert_operator width[:horizontal], :>, 3
    assert_operator width[:stacked], :<, 2
  end

  test "the favicon and app icon are the logo mark" do
    # The favicon is drawn per request in the saved accent (IconsControllerTest);
    # its source is the mark, square and uncolored.
    favicon = Nokogiri::XML(IconsController::FAVICON.read)
    mark = Nokogiri::XML(Rails.root.join("docs/brand/logo-mark.svg").read)
    assert_equal mark.css("path").map { _1["d"] }, favicon.css("path").map { _1["d"] }, "the favicon isn't the mark"
    assert_empty favicon.xpath("//*[@fill or @stroke or @style]")
    width, height = favicon.root["viewBox"].split.last(2).map(&:to_f)
    assert_equal width, height, "a favicon is square"
    assert_not Rails.public_path.join("favicon.svg").exist?, "a static favicon.svg would be served instead of the themed one"

    icon = Vips::Image.new_from_file(Rails.public_path.join("app-icon.png").to_s)
    assert_equal [ 512, 512 ], [ icon.width, icon.height ]
    assert_equal [ 0, 0, 0 ], icon.getpoint(4, 4).first(3).map(&:round), "the app icon sits on the brand black"
    assert_equal [ 96, 114, 72 ], icon.getpoint(256, 300).first(3).map(&:round), "no mark at the center"
    assert_not Rails.public_path.join("icon.png").exist?, "Rails' placeholder icon is still there"
  end

  test "the stylesheet fills each part from the theme" do
    css = Rails.root.join("app/assets/stylesheets/application.css").read
    { "logo-mark" => "--accent", "logo-tagline" => "--accent", "logo-name" => "--ink" }.each do |part, variable|
      rule = css.scan(/([^{}]+)\{([^}]*)\}/).find { |selector, _| selector.include?(".#{part}") }
      assert rule, "nothing colors .#{part}"
      assert_match(/fill:\s*var\(#{variable}\)/, rule.last, ".#{part} isn't filled with #{variable}")
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
