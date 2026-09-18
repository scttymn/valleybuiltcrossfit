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

  test "a color equal to the default is stored as no custom color" do
    # The editor's fields always hold a color, so saving Settings for any reason
    # submits the defaults. Stored as nil, the site keeps following the defaults.
    site = sites(:main)
    site.update!(theme_background: Theme::DEFAULTS[:background].upcase, theme_accent: "#aa3322")

    assert_nil site.theme_background
    assert_equal "#aa3322", site.theme_accent
    assert site.theme_customized?

    site.update!(theme_accent: Theme::DEFAULTS[:accent])
    assert_not site.theme_customized?
  end

  test "border width is 1 to 4 pixels, and blank or the default means default" do
    site = sites(:main)

    site.update!(theme_border_width: 3)
    assert_equal 3, site.theme.border_width
    assert site.theme_customized?

    site.update!(theme_border_width: Theme::DEFAULT_BORDER_WIDTH)
    assert_nil site.theme_border_width
    site.update!(theme_border_width: "")
    assert_nil site.theme_border_width

    [ 0, 5 ].each do |bad|
      site.theme_border_width = bad
      assert_not site.valid?, "accepted #{bad}"
    end
  end

  test "the danger color is stored like the other colors" do
    site = sites(:main)

    site.update!(theme_danger: "CC3344")
    assert_equal "#cc3344", site.theme.danger
    site.update!(theme_danger: Theme::DEFAULTS[:danger].upcase)
    assert_nil site.theme_danger
  end

  test "the photo style is one of the named styles, and the default is stored as nil" do
    site = sites(:main)

    site.update!(theme_photo_style: "tint_darken")
    assert_equal "tint_darken", site.theme.photo_style
    assert site.theme_customized?

    site.update!(theme_photo_style: Theme::DEFAULT_PHOTO_STYLE)
    assert_nil site.theme_photo_style

    site.theme_photo_style = "sepia"
    assert_not site.valid?
  end

  test "directions open in Apple Maps or Google Maps, both to the same address" do
    site = sites(:main)
    links = site.directions_links

    assert_equal [ "Apple Maps", "Google Maps" ], links.keys
    encoded = CGI.escape(site.full_address)
    links.each_value { |url| assert_includes url, encoded }
    assert links.values.all? { _1.start_with?("https://") }
  end

  test "the map location is a real latitude and longitude, or none" do
    site = sites(:main)
    [ [ 39.0252, -94.2159 ], [ nil, nil ] ].each do |lat, lng|
      site.assign_attributes(map_latitude: lat, map_longitude: lng)
      assert site.valid?, "refused #{lat.inspect}, #{lng.inspect}"
    end
    [ [ 91, 0 ], [ 0, -181 ], [ 39.0, nil ], [ nil, -94.2 ] ].each do |lat, lng|
      site.assign_attributes(map_latitude: lat, map_longitude: lng)
      assert_not site.valid?, "accepted #{lat.inspect}, #{lng.inspect}"
    end
  end

  test "the chat widget ID is a PushPress Grow ID, or blank for no chat" do
    site = sites(:main)
    [ "6aadb116599f010aecda2679", "", nil ].each do |id|
      site.chat_widget_id = id
      assert site.valid?, "refused #{id.inspect}"
    end
    [ "6a9092f9", "6a9092f9bde3d5bf505a408g", %("><script>) ].each do |id|
      site.chat_widget_id = id
      assert_not site.valid?, "accepted #{id.inspect}"
    end
    site.chat_widget_id = " 6AADB116599F010AECDA2679 "
    assert site.valid?
    assert_equal "6aadb116599f010aecda2679", site.chat_widget_id, "pasted IDs are tidied"
  end
end
