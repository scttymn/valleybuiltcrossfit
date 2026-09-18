require "test_helper"

class WarmVariantsJobTest < ActiveJob::TestCase
  test "builds every size the layout asks for, so no visitor waits for one" do
    site = sites(:main)
    site.hero_photo.attach(io: Rails.root.join("db/seed_images/hero.webp").open, filename: "hero.webp")

    widths = ApplicationHelper::PHOTO_SIZES.fetch(:hero).fetch(:widths)
    widths.each do |width|
      assert_not ApplicationController.helpers.web_variant(site.hero_photo, width).send(:processed?),
                 "#{width}px should not exist before the job runs"
    end

    WarmVariantsJob.perform_now

    widths.each do |width|
      assert ApplicationController.helpers.web_variant(site.hero_photo, width).send(:processed?),
             "#{width}px was never built"
    end
  end

  test "one unreadable photo does not stop the rest" do
    program = programs(:crossfit)
    program.photo.attach(io: StringIO.new("not an image"), filename: "broken.webp", content_type: "image/webp")

    assert_nothing_raised { WarmVariantsJob.perform_now }
  end
end
