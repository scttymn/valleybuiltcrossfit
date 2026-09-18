require "test_helper"

# The public stylesheet's colors all come from one small palette in :root. A
# theme can only work if that holds — a color typed straight into a rule would
# ignore any change to the palette — and CSS gives no error for a misspelled
# variable: it just renders nothing.
class PaletteTest < ActiveSupport::TestCase
  STYLESHEET = Rails.root.join("app/assets/stylesheets/site.css")
  # A palette entry is a custom property whose whole value is one hex color.
  TOKEN_DEFINITION = /^\s*--([\w-]+):\s*(#\h{6})\s*;/
  COLOR_LITERAL = /(?<=[\s:(,])#\h{3,8}\b|\b(?:rgba?|hsla?)\(/
  MINIMUM_DISTANCE = 3.0 # CIE76 ΔE; two tokens closer than this are one color

  setup do
    @css = STYLESHEET.read.gsub(%r{/\*.*?\*/}m, "") # comments may name colors
    @root = @css[/:root\s*\{(.*?)\n\}/m, 1] or flunk ":root block not found"
    @palette = @root.scan(TOKEN_DEFINITION).to_h
  end

  test "every variable the stylesheet uses is defined" do
    # Layout values like --program-count are set per element in a style
    # attribute; those count too. Anything left over is a typo or a leftover
    # from a rename.
    inline = Rails.root.glob("app/views/**/*.erb").flat_map { |view| view.read.scan(/style="[^"]*/).join.scan(/--([\w-]+):/) }
    defined = (@css.scan(/--([\w-]+):/) + inline).flatten
    used = @css.scan(/var\(--([\w-]+)/).flatten.uniq

    assert_empty used - defined, "these render as nothing because nothing defines them"
  end

  test "every color token in :root is used" do
    used = @css.scan(/var\(--([\w-]+)/).flatten.uniq

    assert_empty @palette.keys - used, "dead palette entries"
  end

  test "no color literal appears outside :root" do
    stray = @css.lines.each_with_index.filter_map do |line, i|
      next if line.match?(TOKEN_DEFINITION)
      "line #{i + 1}: #{line.strip}" if line.match?(COLOR_LITERAL)
    end

    assert_empty stray, "these colors would ignore the theme"
  end

  test "no two palette tokens are within ΔE 3 of each other" do
    close = @palette.to_a.combination(2).filter_map do |(a, hex_a), (b, hex_b)|
      distance = delta_e(hex_a, hex_b)
      "--#{a} #{hex_a} ~ --#{b} #{hex_b} (ΔE #{distance.round(1)})" if distance < MINIMUM_DISTANCE
    end

    assert_empty close, "indistinguishable colors — merge them"
  end

  private
    def delta_e(a, b) = lab(a).zip(lab(b)).sum { |x, y| (x - y)**2 }**0.5

    # sRGB hex → CIE L*a*b* (D65).
    def lab(hex)
      r, g, b = hex.delete("#").scan(/../).map do |channel|
        v = channel.to_i(16) / 255.0
        v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
      end
      x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047
      y = r * 0.2126 + g * 0.7152 + b * 0.0722
      z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883
      f = ->(t) { t > 0.008856 ? t**(1.0 / 3) : 7.787 * t + 16.0 / 116 }
      [ 116 * f[y] - 16, 500 * (f[x] - f[y]), 200 * (f[y] - f[z]) ]
    end
end
