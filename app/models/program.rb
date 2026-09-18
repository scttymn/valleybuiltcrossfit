class Program < ApplicationRecord
  include Positioned
  CTAS = { "" => "None", "schedule" => "See this week's classes", "personal_training" => "Ask about personal training" }.freeze

  include WarmsPhotoVariants
  has_one_attached :photo
  validates :name, presence: true
  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :cta, inclusion: { in: CTAS.keys }, allow_nil: true
  before_validation { self.key = name.to_s.parameterize if key.blank? }
end
