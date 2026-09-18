require "test_helper"

# The site and admin stylesheets take every color from the theme
# (Theme#variables, emitted into the page by both layouts). A theme can only
# work if that holds — a color typed straight into a rule would ignore it — and
# CSS gives no error for a misspelled variable: it just renders nothing.
class PaletteTest < ActiveSupport::TestCase
  STYLESHEETS = %w[site.css admin.css].map { Rails.root.join("app/assets/stylesheets", _1) }
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

  test "no two theme colors are within ΔE 3 of each other" do
    close = @theme.to_a.combination(2).filter_map do |(a, x), (b, y)|
      distance = Theme.delta_e(x, y)
      "#{a} #{x} ~ #{b} #{y} (ΔE #{distance.round(1)})" if distance < 3
    end

    assert_empty close, "indistinguishable colors — merge them"
  end
end
