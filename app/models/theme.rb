# The public site's colors, derived from three the admin picks: background, text
# and accent. The stylesheet paints only with the variables this emits.
#
# Every other shade is the background moved some way toward the text and some
# way toward the accent, in CIE Lab:
#
#   shade = background + s·(text − background) + u·(accent − background)
#
# The (s, u) pairs were fitted to the hand-built palette, which the defaults
# reproduce within ΔE 1.5 — invisible. Because each shade moves toward whatever
# the text and accent are, a light theme comes out right too: its surfaces go a
# touch darker than white and its slot tints go pale green.
class Theme
  HEX = /\A#\h{6}\z/
  DEFAULTS = { background: "#000000", text: "#f2f1e8", accent: "#607248" }.freeze

  SHADES = {
    "surface" => [ -0.049, 0.173 ],
    "surface-2" => [ -0.074, 0.308 ],
    "line" => [ -0.011, 0.309 ],
    "line-strong" => [ 0.031, 0.432 ],
    "muted-soft" => [ 0.333, 0.365 ],
    "muted" => [ 0.543, 0.209 ],
    "ink-soft" => [ 0.786, 0.129 ],
    "accent-wash" => [ -0.098, 0.419 ],
    "accent-wash-2" => [ -0.079, 0.493 ],
    "accent-edge" => [ -0.072, 0.605 ],
    "accent-border" => [ 0.003, 0.639 ],
    "accent-dim" => [ 0.163, 0.991 ],
    "accent-pale" => [ 0.589, 0.641 ]
  }.freeze

  # Errors stay red whatever the accent is: they mean something went wrong.
  FIXED = { "danger-bg" => "#2a1812", "danger-line" => "#7a3b2a", "danger-ink" => "#f0c2b0" }.freeze

  attr_reader :background, :text, :accent

  def self.default = new(**DEFAULTS)

  def initialize(background:, text:, accent:)
    @background, @text, @accent = [ background, text, accent ].map do |color|
      raise ArgumentError, "not a #rrggbb color: #{color.inspect}" unless color.is_a?(String) && color.match?(HEX)
      color.downcase
    end
  end

  def variables
    @variables ||= begin
      base, toward_text, toward_accent = Color.lab(background), Color.lab(text), Color.lab(accent)
      shades = SHADES.transform_values do |s, u|
        Color.hex(base.zip(toward_text, toward_accent).map { |b, t, a| b + s * (t - b) + u * (a - b) })
      end

      { "bg" => background, "ink" => text, "accent" => accent }.merge(shades, FIXED).transform_keys { "--#{_1}" }
    end
  end

  # For a <style> tag. Every value is a validated or computed #rrggbb, so there
  # is nothing in here that could close the tag.
  def to_css = ":root{#{variables.map { |token, value| "#{token}:#{value}" }.join(";")}}"

  # WCAG 2 contrast ratio, 1–21.
  def self.contrast(a, b)
    lighter, darker = [ Color.luminance(a), Color.luminance(b) ].sort.reverse
    (lighter + 0.05) / (darker + 0.05)
  end

  # CIE76 ΔE: under ~2 is invisible, under ~5 barely noticeable side by side.
  def self.delta_e(a, b) = Color.lab(a).zip(Color.lab(b)).sum { |x, y| (x - y)**2 }**0.5

  # sRGB ↔ CIE Lab (D65).
  module Color
    WHITE = [ 0.95047, 1.0, 1.08883 ].freeze

    module_function

    def lab(hex)
      r, g, b = channels(hex).map { linear(_1) }
      xyz = [ r * 0.4124 + g * 0.3576 + b * 0.1805, r * 0.2126 + g * 0.7152 + b * 0.0722, r * 0.0193 + g * 0.1192 + b * 0.9505 ]
      fx, fy, fz = xyz.zip(WHITE).map { |v, w| f(v / w) }
      [ 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz) ]
    end

    # Out-of-gamut results are clamped, so any input yields a valid color.
    def hex(lab)
      l, a, b = lab
      fy = (l + 16) / 116.0
      x, y, z = [ fy + a / 500.0, fy, fy - b / 200.0 ].zip(WHITE).map { |t, w| f_inverse(t) * w }
      rgb = [ 3.2406 * x - 1.5372 * y - 0.4986 * z, -0.9689 * x + 1.8758 * y + 0.0415 * z, 0.0557 * x - 0.2040 * y + 1.0570 * z ]
      format("#%02x%02x%02x", *rgb.map { (gamma(it.clamp(0.0, 1.0)) * 255).round })
    end

    def luminance(hex)
      r, g, b = channels(hex).map { linear(_1) }
      0.2126 * r + 0.7152 * g + 0.0722 * b
    end

    def channels(hex) = hex.delete_prefix("#").scan(/../).map { _1.to_i(16) / 255.0 }
    def linear(v) = v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
    def gamma(v) = v <= 0.0031308 ? 12.92 * v : 1.055 * v**(1 / 2.4) - 0.055
    def f(t) = t > 0.008856 ? t**(1.0 / 3) : 7.787 * t + 16.0 / 116
    def f_inverse(t) = t**3 > 0.008856 ? t**3 : (t - 16.0 / 116) / 7.787
  end
end
