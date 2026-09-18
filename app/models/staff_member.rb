# Coaches and owners. The website shows owners in the wide card at the top of
# the section and coaches in the grid below; the admin edits them in one place.
class StaffMember < ApplicationRecord
  include Positioned

  KINDS = { "coach" => "Coach", "owner" => "Owner" }.freeze

  has_one_attached :photo
  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS.keys }

  scope :owners, -> { ordered.where(kind: "owner") }
  scope :coaches, -> { ordered.where(kind: "coach") }

  def owner? = kind == "owner"
end
