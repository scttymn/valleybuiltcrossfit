# Hands a new inquiry to the gym's PushPress Grow workflow.
class SendLeadToWorkflowJob < ApplicationJob
  queue_as :default
  # Out of retries: fall back to emailing the gym so an inquiry is never lost.
  retry_on Pushpress::Workflow::Error, Timeout::Error, SocketError, wait: :polynomially_longer, attempts: 5 do |job, error|
    lead = job.arguments.first
    Rails.logger.error("[leads] giving up on the PushPress workflow for lead #{lead.id}: #{error.message}")
    LeadMailer.with(lead:).notify.deliver_later
  end
  discard_on ActiveRecord::RecordNotFound

  def perform(lead, workflow: Pushpress::Workflow)
    return if lead.synced_at?

    unless workflow.configured?
      lead.update!(pushpress_error: "No PushPress webhook configured")
      LeadMailer.with(lead:).notify.deliver_later
      return
    end

    workflow.deliver(lead.webhook_payload)
    lead.update!(synced_at: Time.current, pushpress_error: nil)
  rescue Pushpress::Workflow::Error => e
    lead.update!(pushpress_error: e.message.first(500))
    raise
  end
end
