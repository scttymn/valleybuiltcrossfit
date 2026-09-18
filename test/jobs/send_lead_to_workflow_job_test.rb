require "test_helper"

class SendLeadToWorkflowJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  # Stands in for Pushpress::Workflow.
  class FakeWorkflow
    attr_reader :payloads

    def initialize(configured: true, error: nil)
      @configured, @error, @payloads = configured, error, []
    end

    def configured? = @configured

    def deliver(payload)
      raise Pushpress::Workflow::Error, @error if @error
      @payloads << payload
      "ok"
    end
  end

  test "sends the whole inquiry, including the answers PushPress contacts can't hold" do
    workflow = FakeWorkflow.new
    lead = leads(:sam)

    SendLeadToWorkflowJob.new.perform(lead, workflow:)

    payload = workflow.payloads.sole
    assert_equal "sam@example.com", payload[:email]
    assert_equal "Sam Lee", payload[:full_name]
    assert_equal [ "Beginner", "CrossFit", "Just me" ], payload.values_at(:starting_from, :interested_in, :who_is_joining)
    assert_equal "Website — Get your options & pricing", payload[:source]
    assert lead.reload.synced?
  end

  test "doesn't send the same inquiry twice" do
    workflow = FakeWorkflow.new
    lead = leads(:sam)
    2.times { SendLeadToWorkflowJob.new.perform(lead, workflow:) }

    assert_equal 1, workflow.payloads.size
  end

  test "records a failure and retries" do
    lead = leads(:sam)

    assert_raises(Pushpress::Workflow::Error) do
      SendLeadToWorkflowJob.new.perform(lead, workflow: FakeWorkflow.new(error: "PushPress webhook returned 500"))
    end

    assert_not lead.reload.synced?
    assert_match "returned 500", lead.pushpress_error
  end

  test "emails the gym when no webhook is configured" do
    lead = leads(:sam)

    assert_enqueued_emails 1 do
      SendLeadToWorkflowJob.new.perform(lead, workflow: FakeWorkflow.new(configured: false))
    end

    assert_not lead.reload.synced?
    assert_match "No PushPress webhook configured", lead.pushpress_error
  end

  test "a delivered inquiry doesn't email the gym — the workflow handles that" do
    assert_no_enqueued_emails do
      SendLeadToWorkflowJob.new.perform(leads(:sam), workflow: FakeWorkflow.new)
    end
  end

  test "a new inquiry queues the hand-off" do
    assert_enqueued_with job: SendLeadToWorkflowJob do
      Lead.create!(first_name: "Alex", email: "alex@example.com", starting_from: "Beginner", interest: "CrossFit", who: "Just me")
    end
  end
end
