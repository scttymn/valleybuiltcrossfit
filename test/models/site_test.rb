require "test_helper"

class SiteTest < ActiveSupport::TestCase
  test "instance builds a valid singleton on an empty table" do
    Site.delete_all

    site = Site.instance

    assert site.persisted?, "Site.instance must save, or seeds and every page blow up"
    assert_equal 80, site.image_quality
    assert_equal site, Site.instance, "a second call reuses the row"
  end
end
