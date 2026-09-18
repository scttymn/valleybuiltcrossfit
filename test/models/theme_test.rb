require "test_helper"

class ThemeTest < ActiveSupport::TestCase
  # The layer shades the design built by hand, and the three colors it was built
  # around. The layers still sit where the design put them.
  HAND_BUILT_BASE = { background: "#000000", text: "#f2f1e8", accent: "#607248" }.freeze
  HAND_BUILT_LAYERS = { "surface" => "#0a0d03", "line" => "#202318", "accent-wash" => "#181d0e" }.freeze

  LIGHT = { background: "#ffffff", text: "#1b1b1b", accent: "#607248" }.freeze
  # Saturated and far from the logo: navy, white, orange.
  VIVID = { background: "#1a1446", text: "#ffffff", accent: "#ff8a3d" }.freeze

  test "the layer shades stay where the design put them" do
    variables = Theme.new(**HAND_BUILT_BASE).variables

    off = HAND_BUILT_LAYERS.filter_map do |token, was|
      now = variables["--#{token}"]
      "--#{token}: #{was} → #{now}" if Theme.delta_e(was, now) > 2
    end
    assert_empty off
  end

  test "every pairing meets its minimum for the logo, light, and vivid themes" do
    { logo: Theme::DEFAULTS, light: LIGHT, vivid: VIVID }.each do |name, colors|
      failing = Theme.new(**colors).pairings.reject(&:passes?).map { "#{_1.label}: #{_1.ratio.round(1)}:1 < #{_1.minimum}" }
      assert_empty failing, "#{name} theme"
    end
  end

  test "muted and accent text land at 4.5:1 on the hardest background, not above it" do
    [ Theme.default, Theme.new(**LIGHT), Theme.new(**VIVID) ].each do |theme|
      variables = theme.variables
      hardest = theme.hardest_background
      %w[--muted --accent-text].each do |token|
        ratio = Theme.contrast(variables[token], hardest)
        assert_operator ratio, :>=, 4.5, "#{token} on #{hardest}"
        assert_operator ratio, :<, 5.0, "#{token} overshot — it could sit closer to the background" unless variables[token] == theme.accent
      end
    end
  end

  test "when the picks can't reach a target, text shades stop at the text color" do
    theme = Theme.new(background: "#000000", text: "#333333", accent: "#607248")

    assert_equal "#333333", theme.variables["--muted"]
    assert_equal "#333333", theme.variables["--ink-soft"]
    assert theme.warnings.any? { _1.part == :text }, "the unreadable pick itself is flagged"
  end

  test "text on the accent is whichever of background or text reads better" do
    assert_equal "#000000", Theme.default.variables["--on-accent"]
    dark_accent = Theme.new(background: "#000000", text: "#ffffff", accent: "#1f3a8a")
    assert_equal "#ffffff", dark_accent.variables["--on-accent"]
  end

  test "the defaults are the colors of the client's logo" do
    # docs/brand/vbc-logo.png is the file the client supplied. Its three most
    # common colors — the background, then the lettering, then the mark — are
    # the brand, so a new logo can't leave the defaults behind.
    logo = Vips::Image.new_from_file(Rails.root.join("docs/brand/vbc-logo.png").to_s).extract_band(0, n: 3)
    counts = Hash.new(0)
    logo.to_a.each { |row| row.each { |pixel| counts[pixel] += 1 } }
    background, lettering, mark = counts.max_by(3) { _2 }.map { |(rgb, _)| format("#%02x%02x%02x", *rgb) }

    # Danger isn't in the logo; the other three are.
    assert_equal({ background:, text: lettering, accent: mark }, Theme::DEFAULTS.slice(:background, :text, :accent))
  end

  test "the defaults are distinct and warning-free" do
    assert_empty Theme.default.warnings
    close = Theme.default.palette.to_a.combination(2).select { |(_, x), (_, y)| Theme.delta_e(x, y) < 3 }
    assert_empty close
  end

  test "a light theme derives distinct colors" do
    close = Theme.new(**LIGHT).palette.to_a.combination(2).filter_map do |(a, x), (b, y)|
      "#{a} #{x} ~ #{b} #{y}" if Theme.delta_e(x, y) < 3
    end
    assert_empty close, "shades collapse into each other on a light background"
  end

  test "saturated or extreme inputs still produce valid hex for every token" do
    [
      { background: "#ff0000", text: "#00ffff", accent: "#0000ff" },
      { background: "#ffffff", text: "#ffffff", accent: "#ffffff" },
      { background: "#000000", text: "#000000", accent: "#000000" }
    ].each do |colors|
      Theme.new(**colors).palette.each do |token, value|
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

  test "the danger pick reproduces today's delete-link and error colors" do
    variables = Theme.default.variables
    { "--danger" => "#e0785a", "--danger-bg" => "#2a1812", "--danger-line" => "#7a3b2a", "--danger-ink" => "#f0c2b0" }.each do |token, was|
      assert_operator Theme.delta_e(was, variables[token]), :<=, 2.5, "#{token}: #{was} → #{variables[token]}"
    end
  end

  test "a dark danger pick still gives readable delete links and error text" do
    theme = Theme.new(**Theme::DEFAULTS, danger: "#5a0000")
    variables = theme.variables

    assert_operator Theme.contrast(variables["--danger"], theme.hardest_background), :>=, 4.5
    assert_operator Theme.contrast(variables["--danger-ink"], variables["--danger-bg"]), :>=, 4.5
  end

  test "border width defaults to 2px and reaches the stylesheet as a variable" do
    assert_equal "2px", Theme.default.variables["--border-width"]
    assert_equal "3px", Theme.new(**Theme::DEFAULTS, border_width: 3).variables["--border-width"]
    assert_not_includes Theme.default.palette.keys, "--border-width", "a width is not a color"
  end

  test "a border width outside 1–4 is refused" do
    [ 0, 5, -1, "2px", "2; }", nil ].each do |bad|
      assert_raises(ArgumentError, "accepted #{bad.inspect}") { Theme.new(**Theme::DEFAULTS, border_width: bad) }
    end
  end

  test "each photo style sets the photo variables, and None changes nothing" do
    none = Theme.default.variables
    assert_equal "none", Theme.default.photo_style
    assert_equal [ "none", "0", "0" ], none.values_at("--photo-filter", "--photo-tint", "--photo-darken")

    Theme::PHOTO_STYLES.each_key do |style|
      variables = Theme.new(**Theme::DEFAULTS, photo_style: style).variables
      assert_equal Theme::PHOTO_STYLES[style][:filter], variables["--photo-filter"], style
    end
    duotone = Theme.new(**Theme::DEFAULTS, photo_style: "duotone").variables
    assert_match(/grayscale/, duotone["--photo-filter"])
    assert_not_includes Theme.default.palette.keys, "--photo-tint", "a photo setting is not a color"
  end

  test "the map is drawn in the theme: ground in the background color, roads and labels in the text color" do
    dark = Theme.default.variables
    assert_match(/invert\(1\)/, dark["--map-filter"], "a dark theme turns the light map dark")
    assert_equal "multiply", dark["--map-lines-blend"]
    assert_equal "screen", dark["--map-ground-blend"]

    light = Theme.new(**Theme::DEFAULTS, background: "#f4efe6", text: "#1c1c1c").variables
    assert_no_match(/invert/, light["--map-filter"], "a light theme keeps the map light")
    assert_equal "screen", light["--map-lines-blend"]
    assert_equal "multiply", light["--map-ground-blend"]

    assert_not_includes Theme.default.palette.keys, "--map-filter", "a map setting is not a color"
  end

  test "an unknown photo style is refused" do
    [ "sepia", "", nil, "none; } body { display: none" ].each do |bad|
      assert_raises(ArgumentError, "accepted #{bad.inspect}") { Theme.new(**Theme::DEFAULTS, photo_style: bad) }
    end
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
