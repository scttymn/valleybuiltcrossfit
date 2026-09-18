# The site's colors — public pages and admin alike — derived from three the
# admin picks: background, text and accent. The stylesheets paint only with the
# variables this emits. The defaults are the logo's three colors.
#
# Ten colors in all. Besides the three picks:
#
# * Four layers — surface, line, line-strong, accent-wash — sit a fixed step
#   from the background, moved some way toward the text (s) and toward the
#   accent (u) in CIE Lab: background + s·(text − background) + u·(accent −
#   background). The steps were fitted to the hand-built design, and because
#   they move toward whatever the picks are, a light theme layers correctly too.
#
# * Three text shades — muted, ink-soft, accent-text — are set by the contrast
#   they must reach on the hardest background they sit on, so they are readable
#   for any three picks, not just the defaults. Only the picks themselves can
#   fail, and the editor warns about those.
class Theme
  HEX = /\A#\h{6}\z/
  DEFAULTS = { background: "#000000", text: "#d3c7b8", accent: "#607248" }.freeze

  LAYERS = {
    "surface" => [ -0.049, 0.173 ],
    "line" => [ -0.011, 0.309 ],
    "line-strong" => [ -0.010, 0.552 ],
    "accent-wash" => [ -0.14, 0.49 ]
  }.freeze

  # WCAG AA for normal-size text.
  TEXT_CONTRAST = 4.5

  # Delete links start from this red and move only as far as they must to read.
  DANGER = "#e0785a"
  # The error box keeps its own colors whatever the theme: they mean something
  # went wrong, and they read against each other, not the page.
  FIXED = { "danger-bg" => "#2a1812", "danger-line" => "#7a3b2a", "danger-ink" => "#f0c2b0" }.freeze
  # Names for another palette color, not colors of their own.
  ALIASES = %w[--on-accent].freeze

  # Every place the stylesheets put text on a color, and the contrast it needs:
  # 4.5 for normal text, 3 for large text, 0 for disabled and decorative text,
  # which WCAG exempts. The admin guide and the tests both read this list.
  Pairing = Data.define(:label, :foreground, :background, :minimum)
  PAIRINGS = [
    Pairing["Body text", "--ink", "--bg", 4.5],
    Pairing["Body text on cards", "--ink", "--surface", 4.5],
    Pairing["Class times on a schedule slot", "--ink", "--accent-wash", 4.5],
    Pairing["Secondary text", "--ink-soft", "--bg", 4.5],
    Pairing["Secondary text on cards", "--ink-soft", "--surface", 4.5],
    Pairing["Class names on a slot", "--ink-soft", "--accent-wash", 4.5],
    Pairing["Muted text", "--muted", "--bg", 4.5],
    Pairing["Muted text on cards", "--muted", "--surface", 4.5],
    Pairing["Coach names on a slot", "--muted", "--accent-wash", 4.5],
    Pairing["Links and small green labels", "--accent-text", "--bg", 4.5],
    Pairing["Small green text on cards", "--accent-text", "--surface", 4.5],
    Pairing["Spots left on a slot", "--accent-text", "--accent-wash", 4.5],
    Pairing["Headline accent (large text)", "--accent", "--bg", 3.0],
    Pairing["Filled button text (large text)", "--on-accent", "--accent", 3.0],
    Pairing["Filled button on hover (large text)", "--bg", "--ink", 3.0],
    Pairing["Announcement bar", "--bg", "--ink", 4.5],
    Pairing["Announcement bar link on hover", "--bg", "--ink-soft", 4.5],
    Pairing["Outlined button border", "--accent", "--bg", 3.0],
    Pairing["Text on small green buttons", "--bg", "--accent-text", 4.5],
    Pairing["Delete links", "--danger", "--bg", 4.5],
    Pairing["Delete links on panels", "--danger", "--surface", 4.5],
    Pairing["Error messages", "--danger-ink", "--danger-bg", 4.5],
    Pairing["Buttons in error messages", "--danger-bg", "--danger-ink", 4.5],
    Pairing["Disabled and decorative text", "--line-strong", "--bg", 0]
  ].freeze

  Result = Data.define(:label, :foreground, :background, :ratio, :minimum) do
    def passes? = ratio >= minimum
  end

  # Below these the sample warns; it never blocks a save. Body text follows the
  # WCAG guideline for normal text; the accent, which is mostly headlines,
  # buttons and borders, the one for large text and UI parts.
  MINIMUM_CONTRAST = { text: 4.5, accent: 3.0 }.freeze

  Warning = Data.define(:part, :ratio, :minimum, :suggestion)

  attr_reader :background, :text, :accent

  def self.default = new(**DEFAULTS)

  # Takes what people type — "A8BB5C", " #a8bb5c " — as #rrggbb. Blank is nil
  # (use the default); anything else comes back stripped, for validation to reject.
  def self.normalize(value)
    value = value.to_s.strip
    return if value.empty?

    candidate = value.start_with?("#") ? value : "##{value}"
    candidate.match?(HEX) ? candidate.downcase : value
  end

  def initialize(background:, text:, accent:)
    @background, @text, @accent = [ background, text, accent ].map do |color|
      raise ArgumentError, "not a #rrggbb color: #{color.inspect}" unless color.is_a?(String) && color.match?(HEX)
      color.downcase
    end
  end

  def variables
    @variables ||= begin
      hardest = hardest_background
      muted = reach(TEXT_CONTRAST, against: hardest)
      # Halfway, in contrast, between muted and full text: always a clear step.
      ink_soft = reach(Math.sqrt(TEXT_CONTRAST * Theme.contrast(text, hardest)), against: hardest)

      {
        "--bg" => background, "--ink" => text, "--accent" => accent,
        "--ink-soft" => ink_soft, "--muted" => muted,
        "--accent-text" => Theme.suggest(accent, against: hardest, ratio: TEXT_CONTRAST) || accent,
        "--on-accent" => [ background, text ].max_by { Theme.contrast(_1, accent) },
        "--danger" => Theme.suggest(DANGER, against: hardest, ratio: TEXT_CONTRAST) || DANGER
      }.merge(layers.transform_keys { "--#{_1}" }, FIXED.transform_keys { "--#{_1}" })
    end
  end

  # The colors themselves, without the names that point at one of them.
  def palette = variables.except(*ALIASES)

  def pairings
    PAIRINGS.map do |pairing|
      foreground, background = variables.values_at(pairing.foreground, pairing.background)
      Result.new(label: pairing.label, foreground:, background:, ratio: Theme.contrast(foreground, background), minimum: pairing.minimum)
    end
  end

  # Of the backgrounds text sits on, the one it reads worst against.
  def hardest_background
    [ background, layers["surface"], layers["accent-wash"] ].min_by { Theme.contrast(text, _1) }
  end

  # For a <style> tag. Every value is a validated or computed #rrggbb, so there
  # is nothing in here that could close the tag.
  def to_css = ":root{#{variables.map { |token, value| "#{token}:#{value}" }.join(";")}}"

  def to_h = { background:, text:, accent: }

  # This theme with some colors swapped, from raw input such as preview params.
  # Anything that isn't a color is ignored rather than raised: a half-typed hex
  # in the picker shouldn't break the preview.
  def with(**colors)
    valid = colors.transform_values { Theme.normalize(_1) }.select { |_, value| value&.match?(HEX) }
    Theme.new(**to_h.merge(valid.slice(*DEFAULTS.keys)))
  end

  # Parts that are hard to read against the background.
  def warnings
    MINIMUM_CONTRAST.filter_map do |part, minimum|
      ratio = Theme.contrast(public_send(part), background)
      next if ratio >= minimum

      color = public_send(part)
      Warning.new(part:, ratio:, minimum:, suggestion: Theme.suggest(color, against: background, ratio: minimum))
    end
  end

  # The nearest color to `color` that reaches `ratio` against `against`: the same
  # hue and saturation, with only the lightness moved away from the background —
  # lighter on a dark page, darker on a light one — and no further than needed.
  # nil when no lightness gets there (a mid-gray background can't reach 4.5:1
  # with anything).
  def self.suggest(color, against:, ratio:)
    return color if contrast(color, against) >= ratio

    lightness, a, b = Color.lab(color)
    step = Color.lab(against)[0] < 50 ? 0.5 : -0.5
    lightness.step(step.positive? ? 100 : 0, step) do |l|
      candidate = Color.hex([ l, a, b ])
      return candidate if contrast(candidate, against) >= ratio
    end
    nil
  end

  # WCAG 2 contrast ratio, 1–21.
  def self.contrast(a, b)
    lighter, darker = [ Color.luminance(a), Color.luminance(b) ].sort.reverse
    (lighter + 0.05) / (darker + 0.05)
  end

  # CIE76 ΔE: under ~2 is invisible, under ~5 barely noticeable side by side.
  def self.delta_e(a, b) = Color.lab(a).zip(Color.lab(b)).sum { |x, y| (x - y)**2 }**0.5

  private
    def layers
      @layers ||= begin
        base, toward_text, toward_accent = Color.lab(background), Color.lab(text), Color.lab(accent)
        LAYERS.transform_values do |s, u|
          Color.hex(base.zip(toward_text, toward_accent).map { |b, t, a| b + s * (t - b) + u * (a - b) })
        end
      end
    end

    # The first color on the way from the background to the text that reaches
    # `ratio` against `against`; the text itself when nothing short of it does.
    def reach(ratio, against:)
      from, to = Color.lab(background), Color.lab(text)
      (0..200).each do |i|
        t = i / 200.0
        candidate = Color.hex(from.zip(to).map { |a, b| a + t * (b - a) })
        return candidate if Theme.contrast(candidate, against) >= ratio
      end
      text
    end

  public

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
