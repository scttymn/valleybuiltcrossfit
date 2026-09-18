# Singleton row holding the site-wide copy and settings.
class Site < ApplicationRecord
  has_one_attached :hero_photo

  validates :pushpress_subdomain, presence: true
  IMAGE_QUALITY_RANGE = 40..100

  validates :image_quality, inclusion: { in: IMAGE_QUALITY_RANGE }
  validates :class_capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def self.instance
    first_or_create!(pushpress_subdomain: "valleybuiltcrossfit", class_capacity: 18)
  end

  def announcement_showing? = announcement_visible? && announcement.present?

  def phone_href = "tel:#{phone.to_s.gsub(/\D/, "")}"
  def hero_tag_list = hero_tags.to_s.split("/").map(&:strip).compact_blank
  def address_short = [ address_line1, address_line2, city_state_zip.to_s.sub(/,?\s*\d{5}(-\d{4})?\z/, "").delete(",") ].compact_blank.join(", ")
  def full_address = [ address_line1, address_line2, city_state_zip ].compact_blank.join(", ")
  def directions_url = "https://www.google.com/maps/dir/?api=1&destination=#{CGI.escape(full_address)}"
  def map_embed_url = "https://maps.google.com/maps?q=#{CGI.escape(full_address)}&output=embed"
end
