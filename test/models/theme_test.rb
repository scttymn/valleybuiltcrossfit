require "test_helper"

class ThemeTest < ActiveSupport::TestCase
  # The palette as it stood in site.css before the theme took it over. The
  # default theme has to keep the site looking exactly like this.
  CURRENT_PALETTE = {
    "bg" => "#000000", "surface" => "#0a0d03", "surface-2" => "#13170a",
    "line" => "#202318", "line-strong" => "#343827",
    "muted-soft" => "#6f7563", "muted" => "#939587", "ink-soft" => "#c8c9bc", "ink" => "#f2f1e8",
    "accent-wash" => "#181d0e", "accent-wash-2" => "#212817", "accent-edge" => "#2c351f",
    "accent-border" => "#3f4930", "accent-dim" => "#86996c", "accent" => "#607248", "accent-pale" => "#ccdab7",
    "danger-bg" => "#2a1812", "danger-line" => "#7a3b2a", "danger-ink" => "#f0c2b0"
  }.freeze

  LIGHT = { background: "#ffffff", text: "#1b1b1b", accent: "#607248" }.freeze
  SURFACES = %w[--bg --surface --surface-2].freeze

  test "the default theme reproduces the current palette within ΔE 2" do
    variables = Theme.default.variables

    assert_equal CURRENT_PALETTE.keys.map { "--#{_1}" }.sort, variables.keys.sort
    off = CURRENT_PALETTE.filter_map do |token, was|
      now = variables["--#{token}"]
      distance = Theme.delta_e(was, now)
      "--#{token}: #{was} → #{now} (ΔE #{distance.round(1)})" if distance > 2
    end
    assert_empty off, "the default theme would visibly change the site"
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
