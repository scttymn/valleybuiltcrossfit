require "test_helper"

# The site and admin stylesheets take every color from the theme
# (Theme#variables, emitted into the page by both layouts). A theme can only
# work if that holds — a color typed straight into a rule would ignore it — and
# CSS gives no error for a misspelled variable: it just renders nothing.
class PaletteTest < ActiveSupport::TestCase
  STYLESHEETS = %w[application.css site.css admin.css].map { Rails.root.join("app/assets/stylesheets", _1) }
  COLOR_LITERAL = /(?<=[\s:(,])#\h{3,8}\b|\b(?:rgba?|hsla?)\(/

  setup do
    @css = STYLESHEETS.map(&:read).join("\n").gsub(%r{/\*.*?\*/}m, "") # comments may name colors
    @theme = Theme.default.variables
  end

  test "every variable the stylesheet uses is defined" do
    # Layout values like --program-count are set per element in a style
    # attribute; those count too. Anything left over is a typo or a leftover
    # from a rename.
    inline = Rails.root.glob("app/views/**/*.erb").flat_map { |view| view.read.scan(/style="[^"]*/).join.scan(/--([\w-]+):/) }
    defined = (@css.scan(/--([\w-]+):/) + inline).flatten + @theme.keys.map { _1.delete_prefix("--") }
    used = @css.scan(/var\(--([\w-]+)/).flatten.uniq

    assert_empty used - defined, "these render as nothing because nothing defines them"
  end

  test "every theme color is used by the stylesheet" do
    used = @css.scan(/var\(--([\w-]+)/).flatten.uniq

    assert_empty @theme.keys.map { _1.delete_prefix("--") } - used, "the theme defines colors nothing paints with"
  end

  test "the stylesheets contain no color literals" do
    stray = @css.lines.each_with_index.filter_map do |line, i|
      "line #{i + 1}: #{line.strip}" if line.match?(COLOR_LITERAL)
    end

    assert_empty stray, "these colors would ignore the theme"
  end

  test "every color the stylesheets use for text is in the pairing list" do
    # Admin roles like --a-muted are names for theme colors; follow them.
    aliases = @css.scan(/--(a-[\w-]+):\s*var\(--([\w-]+)\)/).to_h
    text_colors = @css.scan(/(?:^|[;{\s])color:\s*var\(--([\w-]+)\)/).flatten.map { aliases.fetch(_1, _1) }.uniq
    listed = Theme::PAIRINGS.map { _1.foreground.delete_prefix("--") }.uniq

    assert_empty text_colors - listed, "text in these colors isn't checked for contrast anywhere"
  end

  test "button text is never smaller than 19px bold" do
    # The logo green can't carry small text (4.0:1 at best), so button text is
    # sized to count as large text, where WCAG asks for 3:1 — in every variant.
    base = @css[/^\.btn \{[^}]*\}/] or flunk ".btn rule not found"
    assert_operator base[/font-size:\s*([\d.]+)px/, 1].to_f, :>=, 19
    assert_operator base[/font-weight:\s*(\d+)/, 1].to_i, :>=, 700

    shrunk = @css.scan(/^([^{}\n]*\.btn[^{}\n]*)\{([^}]*)\}/).filter_map do |selector, body|
      size = body[/font-size:\s*([\d.]+)px/, 1]
      selector.strip if size && size.to_f < 19
    end
    assert_empty shrunk, "these buttons shrink the text below large-text size"
  end

  test "there are two buttons: filled and outlined, both turning cream on hover" do
    rule = ->(selector) { @css[/^#{Regexp.escape(selector)}\s*\{([^}]*)\}/, 1] or flunk "#{selector} not found" }

    filled, filled_hover = rule[".site a.btn--primary, .btn--primary"], rule[".site a.btn--primary:hover, .btn--primary:hover"]
    assert_includes filled, "background: var(--accent)"
    assert_includes filled_hover, "background: var(--ink)"
    assert_includes filled_hover, "color: var(--bg)"

    outlined, outlined_hover = rule[".site a.btn--ghost, .btn--ghost"], rule[".site a.btn--ghost:hover"]
    assert_includes outlined, "border: var(--border-width) solid var(--accent)"
    assert_includes outlined, "color: var(--ink)"
    assert_includes outlined_hover, "border-color: var(--ink)"
  end

  test "the announcement bar is cream with background-colored text" do
    # Its text is small, so it can't sit on the logo green (4.0:1); the text
    # color reversed reads at 12.6:1 on the defaults, and inverts on a light theme.
    rule = @css[/^\.announce \{[^}]*\}/] or flunk ".announce rule not found"
    assert_includes rule, "background: var(--ink)"
    assert_includes rule, "color: var(--bg)"
  end

  test "no border width is typed into a rule" do
    # Border widths come from the theme's --border-width. Focus outlines are
    # the keyboard-focus ring, not decoration, and keep their own width.
    fixed = @css.lines.each_with_index.filter_map do |line, i|
      "line #{i + 1}: #{line.strip[0, 100]}" if line.match?(/border(?:-(?:top|bottom|left|right))?(?:-width)?:\s*[\d.]+px/)
    end
    assert_empty fixed

    # Grids that draw their dividers as a gap over a line-colored background
    # are borders too, just drawn another way.
    gap_lines = @css.scan(/^([^{}\n]+)\{([^}]*)\}/).filter_map do |selector, body|
      selector.strip if body.match?(/gap:\s*[\d.]+px/) && body.match?(/background:\s*var\(--line/)
    end
    assert_empty gap_lines, "these divide with a fixed-width gap instead of --border-width"
  end

  test "scrollbars are themed: an accent thumb on the card shade, cream on hover" do
    assert_match(/scrollbar-color:\s*var\(--accent\)\s+var\(--surface\)/, @css)
    # Safari still needs the -webkit- pseudo-elements.
    assert_match(/::-webkit-scrollbar-thumb\s*\{[^}]*background:\s*var\(--accent\)/, @css)
    assert_match(/::-webkit-scrollbar-thumb:hover\s*\{[^}]*background:\s*var\(--ink\)/, @css)
  end

  test "no two theme colors are within ΔE 3 of each other" do
    close = Theme.default.palette.to_a.combination(2).filter_map do |(a, x), (b, y)|
      distance = Theme.delta_e(x, y)
      "#{a} #{x} ~ #{b} #{y} (ΔE #{distance.round(1)})" if distance < 3
    end

    assert_empty close, "indistinguishable colors — merge them"
  end
end
