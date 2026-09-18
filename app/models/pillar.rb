class Pillar < ApplicationRecord
  include Positioned
  validates :title, presence: true
end
