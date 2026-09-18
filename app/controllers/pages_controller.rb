class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    @site = Site.instance
    @pillars = Pillar.ordered
    @programs = Program.ordered.with_attached_photo
    @steps = Step.ordered
    @membership_options = MembershipOption.ordered
    @staff = StaffMember.ordered.with_attached_photo
    @faqs = Faq.ordered
    @schedule = Schedule.for_offset(0, site: @site)
    @week = 0
    @lead = Lead.new(interest: Lead::QUESTION)
  end
end
