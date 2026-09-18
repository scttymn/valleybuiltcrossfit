class User < ApplicationRecord
  # Online guessing is held off by the rate limit on SessionsController#create
  # (10 tries per 3 minutes per IP), so this is a floor against a careless
  # password rather than the thing standing between the admin and a brute force.
  MINIMUM_PASSWORD_LENGTH = 7

  # Each rule names what a password must contain, so a rejection can say which
  # one it missed instead of restating the whole policy.
  PASSWORD_RULES = {
    "a capital letter" => /[A-Z]/,
    "a number" => /\d/,
    "a special character" => /[^A-Za-z0-9]/
  }.freeze

  has_secure_password
  has_many :sessions, dependent: :destroy

  # allow_nil so editing an account without touching the password still saves.
  validates :password, length: { minimum: MINIMUM_PASSWORD_LENGTH }, allow_nil: true
  validate :password_meets_rules, if: -> { password.present? }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  private
    def password_meets_rules
      missing = PASSWORD_RULES.reject { |_, pattern| password.match?(pattern) }.keys
      errors.add(:password, "must include #{missing.to_sentence}") if missing.any?
    end
end
