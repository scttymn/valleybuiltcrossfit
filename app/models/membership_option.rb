class MembershipOption < ApplicationRecord
  include Positioned
  validates :name, presence: true
end
