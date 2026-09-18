require "test_helper"

class LeadsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  def valid_params(rendered_at: 30.seconds.ago)
    {
      form_token: LeadsController.form_token_verifier.generate(rendered_at.to_i),
      lead: { first_name: "Alex", email: "alex@example.com", starting_from: "Returning", interest: "Recovery Studio", who: "Family", notes: "Bad knee" }
    }
  end

  test "saves the inquiry and hands it to the PushPress workflow" do
    assert_difference -> { Lead.count } do
      assert_enqueued_with job: SendLeadToWorkflowJob do
        post leads_path, params: valid_params
      end
    end

    assert_response :success
    assert_select ".form-success", /Thanks, Alex/
    assert_equal "Recovery Studio", Lead.last.interest
  end

  test "a plain question skips the qualifying answers" do
    params = valid_params
    params[:lead] = params[:lead].merge(interest: Lead::QUESTION, starting_from: "", who: "", notes: "Do you have showers?")

    assert_difference -> { Lead.count } do
      post leads_path, params: params
    end

    lead = Lead.last
    assert lead.question?
    assert_equal "Website — question", lead.webhook_payload[:source]
  end

  test "a question needs to say what's being asked" do
    params = valid_params
    params[:lead] = params[:lead].merge(interest: Lead::QUESTION, starting_from: "", who: "", notes: "")

    assert_no_difference -> { Lead.count } do
      post leads_path, params: params
    end
    assert_response :unprocessable_entity
  end

  test "shows errors for an invalid inquiry" do
    assert_no_difference -> { Lead.count } do
      post leads_path, params: valid_params.merge(lead: valid_params[:lead].merge(email: "nope", interest: "Yoga"))
    end

    assert_response :unprocessable_entity
    assert_select ".form-errors", /Email is invalid/
  end

  test "quietly drops a submission with no form token" do
    assert_no_difference -> { Lead.count } do
      post leads_path, params: { lead: valid_params[:lead] }
    end
    assert_response :success
    assert_select ".form-success"
  end

  test "quietly drops a forged form token" do
    assert_no_difference -> { Lead.count } do
      post leads_path, params: valid_params.merge(form_token: "not-a-real-token")
    end
    assert_response :success
  end

  test "quietly drops a form submitted faster than a person could type" do
    assert_no_difference -> { Lead.count } do
      post leads_path, params: valid_params(rendered_at: Time.current)
    end
    assert_response :success
  end

  test "quietly drops a stale form token" do
    assert_no_difference -> { Lead.count } do
      post leads_path, params: valid_params(rendered_at: 5.hours.ago)
    end
    assert_response :success
  end

  test "quietly drops honeypot submissions" do
    assert_no_difference -> { Lead.count } do
      post leads_path, params: valid_params.merge(lead: valid_params[:lead].merge(website: "http://spam.example"))
    end
    assert_response :success
  end
end
