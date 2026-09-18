class Workout < ApplicationRecord
  validates :date, presence: true, uniqueness: true

  def rest_day? = rx.blank?
  def scaling? = intermediate.present? || beginner.present?
end
