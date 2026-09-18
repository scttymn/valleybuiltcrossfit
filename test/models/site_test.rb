require "test_helper"

class SiteTest < ActiveSupport::TestCase
  test "instance builds a valid singleton on an empty table" do
    Site.delete_all

    site = Site.instance

    assert site.persisted?, "Site.instance must save, or seeds and every page blow up"
    assert_equal 80, site.image_quality
    assert_equal site, Site.instance, "a second call reuses the row"
  end

  test "theme colors normalize case and a missing #, and blank means default" do
    site = sites(:main)
    site.update!(theme_background: "  FFFFFF ", theme_text: "#1B1B1B", theme_accent: "")

    assert_equal "#ffffff", site.theme_background
    assert_equal "#1b1b1b", site.theme_text
    assert_nil site.theme_accent
    assert_equal Theme::DEFAULTS[:accent], site.theme.accent
  end

  test "theme colors reject anything that isn't six-digit hex" do
    [ "red", "#fff", "#12345g", "rgb(0, 0, 0)", "#000000;}</style><script>" ].each do |bad|
      site = sites(:main)
      site.theme_accent = bad

      assert_not site.valid?, "accepted #{bad.inspect}"
      assert site.errors[:theme_accent].any?, "no error on the field for #{bad.inspect}"
    end
  end
end
