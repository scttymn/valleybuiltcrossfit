class LeadsController < ApplicationController
  allow_unauthenticated_access

  # Each inquiry costs a PushPress workflow execution, so the form is the only
  # way in and it's kept deliberately unattractive to bots: a honeypot field, a
  # signed timestamp that has to come from a real page view, and rate limits.
  MIN_FILL_SECONDS = 3
  FORM_TOKEN_VALIDITY = 4.hours

  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { head :too_many_requests }
  rate_limit to: 30, within: 1.hour, only: :create, by: -> { "leads" }, with: -> { head :too_many_requests }

  def create
    return silently_ignore if spam?

    lead = Lead.new(lead_params)

    unless Turnstile.human?(params["cf-turnstile-response"], ip: request.remote_ip)
      lead.errors.add(:base, "Please confirm you're not a robot and send again")
      return render_form(lead, status: :unprocessable_entity)
    end

    if lead.save
      render_form(lead, sent: true)
    else
      render_form(lead, status: :unprocessable_entity)
    end
  end

  private

  # Bots get the same thank-you a person does, so there's nothing to probe against.
  def silently_ignore
    Rails.logger.info("[leads] ignored a submission that looked automated")
    render_form(Lead.new(first_name: params.dig(:lead, :first_name)), sent: true)
  end

  def spam?
    params.dig(:lead, :website).present? || !plausibly_typed_by_a_person?
  end

  # The form carries a signed timestamp. A missing or forged one means the post
  # didn't come from our page; an instant one means nobody typed the answers.
  def plausibly_typed_by_a_person?
    rendered_at = self.class.form_token_verifier.verified(params[:form_token].to_s)&.to_i
    return false if rendered_at.nil?

    age = Time.current.to_i - rendered_at
    age.between?(MIN_FILL_SECONDS, FORM_TOKEN_VALIDITY.to_i)
  end

  def self.form_token_verifier
    Rails.application.message_verifier(:lead_form)
  end

  def lead_params
    params.expect(lead: %i[first_name last_name email phone starting_from interest who notes])
  end

  def render_form(lead, sent: false, status: :ok)
    render partial: "leads/form", locals: { lead:, sent: }, status:
  end
end
