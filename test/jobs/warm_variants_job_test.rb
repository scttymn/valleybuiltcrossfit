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

  test "builds a photo Active Storage has not identified yet" do
    site = sites(:main)
    site.hero_photo.attach(io: Rails.root.join("db/seed_images/hero.webp").open, filename: "hero.webp")
    # How a blob looks in the window between being attached and being analysed:
    # the job used to read variable? as false here and skip every photo.
    blob = site.hero_photo.blob
    blob.update_columns(content_type: "application/octet-stream",
                        metadata: blob.metadata.except("identified", :identified).to_json)

    WarmVariantsJob.perform_now

    width = ApplicationHelper::PHOTO_SIZES.fetch(:hero).fetch(:widths).last
    assert ApplicationController.helpers.web_variant(site.reload.hero_photo, width).send(:processed?),
           "an unidentified blob was skipped instead of being built"
  end

  test "records a photo's size when Active Storage didn't, so pages can reserve its space" do
    site = sites(:main)
    site.hero_photo.attach(io: Rails.root.join("db/seed_images/hero.webp").open, filename: "hero.webp")
    # How the coach photos were stored: analyzed, but with no width or height.
    blob = site.hero_photo.blob
    blob.update_columns(metadata: { identified: true, analyzed: true }.to_json)

    WarmVariantsJob.perform_now

    metadata = blob.reload.metadata
    assert metadata["width"].to_i.positive? && metadata["height"].to_i.positive?, "no size recorded: #{metadata.inspect}"
  end

  test "one unreadable photo does not stop the rest" do
    program = programs(:crossfit)
    program.photo.attach(io: StringIO.new("not an image"), filename: "broken.webp", content_type: "image/webp")

    assert_nothing_raised { WarmVariantsJob.perform_now }
  end
end
