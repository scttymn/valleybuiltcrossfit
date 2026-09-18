class Step < ApplicationRecord
  include Positioned
  validates :title, presence: true
end
