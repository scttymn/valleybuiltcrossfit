require "test_helper"

class ThemeTest < ActiveSupport::TestCase
  # The palette as it stood in site.css before the theme took it over, and the
  # three colors it was built around. The formula has to reproduce it.
  CURRENT_PALETTE = {
    "bg" => "#000000", "surface" => "#0a0d03", "surface-2" => "#13170a",
    "line" => "#202318", "line-strong" => "#343827",
    "muted-soft" => "#6f7563", "muted" => "#939587", "ink-soft" => "#c8c9bc", "ink" => "#f2f1e8",
    "accent-wash" => "#181d0e", "accent-wash-2" => "#212817", "accent-edge" => "#2c351f",
    "accent-border" => "#3f4930", "accent-dim" => "#86996c", "accent" => "#607248", "accent-pale" => "#ccdab7",
    "danger" => "#e0785a", "danger-bg" => "#2a1812", "danger-line" => "#7a3b2a", "danger-ink" => "#f0c2b0"
  }.freeze

  LIGHT = { background: "#ffffff", text: "#1b1b1b", accent: "#607248" }.freeze
  SURFACES = %w[--bg --surface --surface-2].freeze

  HAND_BUILT_BASE = { background: "#000000", text: "#f2f1e8", accent: "#607248" }.freeze

  test "the formula reproduces the hand-built palette from its three base colors within ΔE 2" do
    variables = Theme.new(**HAND_BUILT_BASE).variables

    assert_equal CURRENT_PALETTE.keys.map { "--#{_1}" }.sort, variables.keys.sort
    off = CURRENT_PALETTE.filter_map do |token, was|
      now = variables["--#{token}"]
      distance = Theme.delta_e(was, now)
      "--#{token}: #{was} → #{now} (ΔE #{distance.round(1)})" if distance > 2
    end
    assert_empty off, "the derived shades drifted from the design"
  end

  test "the defaults are the colors of the client's logo" do
    # docs/brand/vbc-logo.png is the file the client supplied. Its three most
    # common colors — the background, then the lettering, then the mark — are
    # the brand, so a new logo can't leave the defaults behind.
    logo = Vips::Image.new_from_file(Rails.root.join("docs/brand/vbc-logo.png").to_s).extract_band(0, n: 3)
    counts = Hash.new(0)
    logo.to_a.each { |row| row.each { |pixel| counts[pixel] += 1 } }
    background, lettering, mark = counts.max_by(3) { _2 }.map { |(rgb, _)| format("#%02x%02x%02x", *rgb) }

    assert_equal({ background:, text: lettering, accent: mark }, Theme::DEFAULTS)
  end

  test "the defaults are distinct and warning-free" do
    assert_empty Theme.default.warnings
    close = Theme.default.variables.to_a.combination(2).select { |(_, x), (_, y)| Theme.delta_e(x, y) < 3 }
    assert_empty close
  end

  test "a light theme derives distinct colors and keeps text readable on every surface" do
    variables = Theme.new(**LIGHT).variables

    close = variables.to_a.combination(2).filter_map do |(a, x), (b, y)|
      "#{a} #{x} ~ #{b} #{y}" if Theme.delta_e(x, y) < 3
    end
    assert_empty close, "shades collapse into each other on a light background"

    SURFACES.each do |surface|
      ratio = Theme.contrast(variables["--ink"], variables[surface])
      assert_operator ratio, :>=, 4.5, "text on #{surface} is #{ratio.round(1)}:1"
    end
  end

  test "saturated or extreme inputs still produce valid hex for every token" do
    [
      { background: "#ff0000", text: "#00ffff", accent: "#0000ff" },
      { background: "#ffffff", text: "#ffffff", accent: "#ffffff" },
      { background: "#000000", text: "#000000", accent: "#000000" }
    ].each do |colors|
      Theme.new(**colors).variables.each do |token, value|
        assert_match(/\A#\h{6}\z/, value, "#{token} for #{colors}")
      end
    end
  end

  test "anything but six-digit hex is refused" do
    [ "red", "#fff", "#00000g", "#000000;}</style><script>", "", nil ].each do |bad|
      assert_raises(ArgumentError, "accepted #{bad.inspect}") { Theme.new(**Theme::DEFAULTS, accent: bad) }
    end
  end

  test "a suggestion meets the ratio, keeps the hue, and moves as little as it can" do
    suggestion = Theme.suggest("#607248", against: "#000000", ratio: 4.5)

    assert_operator Theme.contrast(suggestion, "#000000"), :>=, 4.5
    assert_operator Theme.contrast(suggestion, "#000000"), :<, 4.8, "overshot — a closer color would have passed"
    assert_in_delta hue("#607248"), hue(suggestion), 3, "the suggestion changed the color, not just its lightness"
  end

  test "on a light background the suggestion goes darker, not lighter" do
    suggestion = Theme.suggest("#a9bc8c", against: "#ffffff", ratio: 4.5)

    assert_operator Theme.contrast(suggestion, "#ffffff"), :>=, 4.5
    assert_operator Theme::Color.lab(suggestion)[0], :<, Theme::Color.lab("#a9bc8c")[0]
  end

  test "a color that already passes is returned unchanged" do
    assert_equal "#f2f1e8", Theme.suggest("#f2f1e8", against: "#000000", ratio: 4.5)
  end

  test "contrast matches WCAG for known pairs" do
    assert_in_delta 21.0, Theme.contrast("#000000", "#ffffff"), 0.01
    assert_in_delta 1.0, Theme.contrast("#607248", "#607248"), 0.01
    assert_in_delta 4.0, Theme.contrast("#607248", "#000000"), 0.05
  end

  private
    def hue(color)
      _, a, b = Theme::Color.lab(color)
      Math.atan2(b, a) * 180 / Math::PI
    end
end
