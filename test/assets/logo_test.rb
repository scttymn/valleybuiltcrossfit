require "test_helper"

# The logo is an SVG drawn into the page, so the theme colors it: the mark and
# the CROSSFIT line in the accent, the name in the text color. It has no colors
# of its own, and nothing blends it into the background.
class LogoTest < ActiveSupport::TestCase
  LOGO = Rails.root.join("app/assets/images/logo-valley-built-horizontal.svg")

  setup { @svg = Nokogiri::XML(LOGO.read) }

  test "the logo has its three parts and no colors of its own" do
    root = @svg.root
    assert_equal "svg", root.name
    assert_match(/\A[-\d.]+ [-\d.]+ [\d.]+ [\d.]+\z/, root["viewBox"])
    %w[logo-mark logo-name logo-tagline].each do |part|
      assert_equal 1, @svg.css("g.#{part}").size, "no #{part}"
      assert_operator @svg.css("g.#{part} path").size, :>=, 1, "#{part} is empty"
    end
    assert_empty @svg.xpath("//*[@fill or @stroke or @style]"), "a color in the file would override the theme"
    assert_empty @svg.xpath("//*[local-name()='script' or local-name()='image' or local-name()='foreignObject']")
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
