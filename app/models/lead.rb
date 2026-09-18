class Lead < ApplicationRecord
  INTRO = "Intro session".freeze
  QUESTION = "Just a question".freeze
  STARTING_FROM = [ "Beginner", "Returning", "Experienced" ].freeze
  INTERESTS = [ INTRO, "CrossFit", "Personal training", "Recovery Studio", QUESTION ].freeze
  WHO = [ "Just me", "Me + partner", "Family", "Student athlete" ].freeze

  validates :first_name, :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :interest, inclusion: { in: INTERESTS }

  # Someone with a question shouldn't have to answer the qualifying ones, but
  # their question is the whole point, so it's required instead.
  with_options unless: :question? do
    validates :starting_from, inclusion: { in: STARTING_FROM, message: "— choose one" }
    validates :who, inclusion: { in: WHO, message: "— choose one" }
  end
  validates :notes, presence: { message: "&mdash; let us know what you'd like to ask" }, if: :question?

  def question? = interest == QUESTION

  # PushPress's workflow does the notifying (staff SMS/email, plus the
  # confirmation to the person), so the site only emails if that never lands.
  after_create_commit { SendLeadToWorkflowJob.perform_later(self) }

  def synced? = synced_at?

  # What the gym's workflow receives. Field names are what they'll map in Grow.
  def webhook_payload
    {
      first_name: first_name,
      last_name: last_name,
      full_name: name,
      email: email,
      phone: phone,
      starting_from: starting_from,
      interested_in: interest,
      who_is_joining: who,
      notes: notes,
      source: question? ? "Website — question" : "Website — Get your options & pricing",
      submitted_at: created_at.iso8601
    }
  end

  def name = [ first_name, last_name ].compact_blank.join(" ")
end
