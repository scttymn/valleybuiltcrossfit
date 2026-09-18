module Positioned
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order(:position, :id) }
    before_create { self.position ||= (self.class.maximum(:position) || 0) + 1 }
  end
end
