class LeadMailer < ApplicationMailer
  def notify
    @lead = params[:lead]
    recipient = Site.instance.lead_notification_email.presence || Site.instance.email
    return if recipient.blank?

    mail to: recipient, reply_to: @lead.email, subject: "New website inquiry: #{@lead.name} (#{@lead.interest})"
  end
end
