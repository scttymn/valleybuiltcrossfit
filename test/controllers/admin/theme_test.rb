require "test_helper"

class Admin::ThemeTest < ActionDispatch::IntegrationTest
  LIGHT = { theme_background: "#ffffff", theme_text: "#1b1b1b", theme_accent: "#607248" }.freeze

  setup { @site = sites(:main) }

  test "admin saves theme colors and the public page uses them" do
    sign_in_as users(:one)

    patch admin_settings_theme_path, params: { site: LIGHT }
    assert_redirected_to edit_admin_settings_theme_path

    get root_path
    assert_includes theme_style, "--bg:#ffffff"
    assert_includes theme_style, "--ink:#1b1b1b"
    assert_select "meta[name='theme-color'][content='#ffffff']"
  end

  test "the admin and the login page use the saved theme" do
    @site.update!(**LIGHT)

    get login_path
    assert_includes theme_style, "--bg:#ffffff", "login page ignores the theme"

    sign_in_as users(:one)
    get admin_root_path
    assert_includes theme_style, "--bg:#ffffff", "admin ignores the theme"
  end

  test "a low-contrast theme still saves, and the preview flags it" do
    sign_in_as users(:one)

    patch admin_settings_theme_path, params: { site: { theme_background: "#000000", theme_text: "#222222" } }
    assert_redirected_to edit_admin_settings_theme_path
    assert_equal "#222222", @site.reload.theme_text, "contrast must never block a save"

    get preview_admin_settings_theme_path, params: { background: "#000000", text: "#222222" }
    assert_select ".theme-warning", text: /text/i
  end

  test "reset colors restores the defaults and leaves other settings alone" do
    sign_in_as users(:one)
    @site.update!(**LIGHT, image_quality: 70)

    patch admin_settings_theme_path, params: { reset_colors: "1", site: { image_quality: 70 } }
    assert_redirected_to edit_admin_settings_theme_path

    @site.reload
    assert_nil @site.theme_background
    assert_nil @site.theme_text
    assert_nil @site.theme_accent
    assert_equal 70, @site.image_quality
  end

  test "reset is offered only when the colors differ from the defaults" do
    sign_in_as users(:one)

    get edit_admin_settings_theme_path
    assert_select "button[name='reset_colors']", 0
    assert_select ".theme-editor__status", /default/i

    @site.update!(theme_accent: "#aa3322")
    get edit_admin_settings_theme_path
    assert_select "button[name='reset_colors']", 1
  end

  test "saving the theme page untouched leaves the colors on the defaults" do
    sign_in_as users(:one)

    # The fields are always filled in, so an untouched save submits the defaults.
    patch admin_settings_theme_path, params: { site: Theme::DEFAULTS.transform_keys { Site::THEME_COLORS[_1] } }

    assert_not @site.reload.theme_customized?, "submitting the prefilled defaults pinned them as custom colors"
  end

  test "anonymous visitors cannot change theme colors" do
    patch admin_settings_theme_path, params: { site: LIGHT }

    assert_redirected_to login_path
    assert_nil @site.reload.theme_background
  end

  test "the theme preview is admin-only" do
    get preview_admin_settings_theme_path, params: { accent: "#ff0000" }
    assert_redirected_to login_path
  end

  test "the preview renders the requested colors without saving them" do
    sign_in_as users(:one)

    get preview_admin_settings_theme_path, params: { background: "#ffffff", text: "#1b1b1b", accent: "#aa3322" }
    assert_response :success
    assert_includes theme_style, "--bg:#ffffff"
    assert_includes theme_style, "--accent:#aa3322"
    assert_nil @site.reload.theme_accent, "previewing must not save"
  end

  test "the preview falls back to the saved theme for invalid colors" do
    sign_in_as users(:one)
    @site.update!(theme_accent: "#aa3322")

    get preview_admin_settings_theme_path, params: { accent: "#000;}</style><script>alert(1)</script>" }
    assert_response :success
    assert_includes theme_style, "--accent:#aa3322"
    assert_not_includes response.body, "alert(1)"
  end

  test "the preview suggests a readable color with a Use this button" do
    sign_in_as users(:one)

    get preview_admin_settings_theme_path, params: { background: "#000000", text: "#222222" }

    button = css_select(".theme-warning button[data-part='text']").first
    assert button, "no Use this button for the text color"
    suggestion = button["data-color"]
    assert_match(/\A#\h{6}\z/, suggestion)
    assert_operator Theme.contrast(suggestion, "#000000"), :>=, 4.5, "the suggestion doesn't fix the problem"
  end

  test "the preview lists every pairing with its ratio and minimum" do
    sign_in_as users(:one)

    get preview_admin_settings_theme_path
    assert_select ".contrast-guide tbody tr", Theme::PAIRINGS.size
    Theme.default.pairings.each do |pairing|
      assert_select ".contrast-guide tr", text: /#{Regexp.escape(pairing.label)}.*#{format("%.1f", pairing.ratio)}:1/m
    end
    assert_select ".contrast-guide tr.is-failing", 0
  end

  test "a pick that fails shows as failing in the guide, with a suggestion" do
    sign_in_as users(:one)

    get preview_admin_settings_theme_path, params: { text: "#333333" }
    assert_select ".contrast-guide tr.is-failing", text: /Body text/
    assert_select ".theme-warning button[data-part='text']"
  end

  test "a border width saved in admin reaches the site, and the preview shows one before saving" do
    sign_in_as users(:one)

    get preview_admin_settings_theme_path, params: { border_width: "3" }
    assert_includes theme_style, "--border-width:3px"
    assert_nil @site.reload.theme_border_width, "previewing must not save"

    patch admin_settings_theme_path, params: { site: { theme_border_width: "2" } }
    get root_path
    assert_includes theme_style, "--border-width:2px"
  end

  test "a danger color saved in admin changes the site's error colors" do
    sign_in_as users(:one)
    expected = Theme.new(**Theme::DEFAULTS, danger: "#cc3344").variables

    get preview_admin_settings_theme_path, params: { danger: "#cc3344" }
    assert_includes theme_style, "--danger-line:#{expected["--danger-line"]}"

    patch admin_settings_theme_path, params: { site: { theme_danger: "#cc3344" } }
    get root_path
    assert_includes theme_style, "--danger-line:#{expected["--danger-line"]}"
  end

  private
    def theme_style = css_select("head style").map(&:text).join
end
