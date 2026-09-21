# Singleton row holding the site-wide copy and settings.
class Site < ApplicationRecord
  include WarmsPhotoVariants
  has_one_attached :hero_photo

  validates :pushpress_subdomain, presence: true
  IMAGE_QUALITY_RANGE = 40..100

  validates :image_quality, inclusion: { in: IMAGE_QUALITY_RANGE }
  validates :class_capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  # PushPress Grow (LeadConnector) widget IDs are 24 hex characters.
  normalizes :chat_widget_id, with: ->(id) { id.strip.downcase.presence }
  validates :chat_widget_id, format: { with: /\A\h{24}\z/, message: "should be the 24-character ID from the widget's embed code" }, allow_nil: true

  def self.instance
    first_or_create!(pushpress_subdomain: "valleybuiltcrossfit", class_capacity: 19)
  end

  # Each part of the theme and the column holding it. nil = Theme::DEFAULTS.
  THEME_COLORS = { background: :theme_background, text: :theme_text, accent: :theme_accent, danger: :theme_danger }.freeze

  # A color equal to its default is stored as nil. The editor's fields always
  # hold a color, so every Settings save submits all three; without this, saving
  # anything would pin the defaults as custom colors and the site would stop
  # following them.
  THEME_COLORS.each do |part, column|
    normalizes column, with: ->(value) { Theme.normalize(value).then { _1 == Theme::DEFAULTS[part] ? nil : _1 } }
  end
  validates(*THEME_COLORS.values, format: { with: Theme::HEX, message: "must be a color like #607248" }, allow_nil: true)

  normalizes :theme_border_width, with: ->(value) { value == Theme::DEFAULT_BORDER_WIDTH ? nil : value }
  validates :theme_border_width, inclusion: { in: Theme::BORDER_WIDTHS, message: "must be 1 to 4 pixels" }, allow_nil: true

  normalizes :theme_photo_style, with: ->(value) { value.presence unless value == Theme::DEFAULT_PHOTO_STYLE }
  validates :theme_photo_style, inclusion: { in: Theme::PHOTO_STYLES.keys, message: "isn't one of the photo styles" }, allow_nil: true

  def theme_customized? = [ *THEME_COLORS.values, :theme_border_width, :theme_photo_style ].any? { self[_1].present? }

  # A stored value that isn't a color — set from the console, say — falls back
  # to the default rather than reaching the page's <style> tag.
  def theme
    colors = THEME_COLORS.to_h { |part, column| [ part, self[column].to_s.match?(Theme::HEX) ? self[column] : Theme::DEFAULTS[part] ] }
    width = theme_border_width if Theme::BORDER_WIDTHS.cover?(theme_border_width.to_i)
    photo_style = theme_photo_style if Theme::PHOTO_STYLES.key?(theme_photo_style)
    Theme.new(**colors, border_width: width || Theme::DEFAULT_BORDER_WIDTH, photo_style: photo_style || Theme::DEFAULT_PHOTO_STYLE)
  end

  def announcement_showing? = announcement_visible? && announcement.present?

  def phone_href = "tel:#{phone.to_s.gsub(/\D/, "")}"
  def hero_tag_list = hero_tags.to_s.split("/").map(&:strip).compact_blank
  def address_short = [ address_line1, address_line2, city_state_zip.to_s.sub(/,?\s*\d{5}(-\d{4})?\z/, "").delete(",") ].compact_blank.join(", ")
  def full_address = [ address_line1, address_line2, city_state_zip ].compact_blank.join(", ")
  # No link opens whichever map app someone uses on every phone, so they pick.
  # Each app finds the address itself, so a moved pin never sends anyone astray.
  def directions_links
    address = CGI.escape(full_address)
    {
      "Apple Maps" => "https://maps.apple.com/?daddr=#{address}",
      "Google Maps" => "https://www.google.com/maps/dir/?api=1&destination=#{address}"
    }
  end
end
