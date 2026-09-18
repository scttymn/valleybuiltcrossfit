require "test_helper"

class Admin::ThemeTest < ActionDispatch::IntegrationTest
  LIGHT = { theme_background: "#ffffff", theme_text: "#1b1b1b", theme_accent: "#607248" }.freeze

  setup { @site = sites(:main) }

  test "admin saves theme colors and the public page uses them" do
    sign_in_as users(:one)

    patch admin_settings_path, params: { site: LIGHT }
    assert_redirected_to edit_admin_settings_path

    get root_path
    assert_includes theme_style, "--bg:#ffffff"
    assert_includes theme_style, "--ink:#1b1b1b"
    assert_select "meta[name='theme-color'][content='#ffffff']"
  end

  test "a low-contrast theme still saves, and the preview flags it" do
    sign_in_as users(:one)

    patch admin_settings_path, params: { site: { theme_background: "#000000", theme_text: "#222222" } }
    assert_redirected_to edit_admin_settings_path
    assert_equal "#222222", @site.reload.theme_text, "contrast must never block a save"

    get theme_preview_admin_settings_path, params: { background: "#000000", text: "#222222" }
    assert_select ".theme-warning", text: /text/i
  end

  test "reset colors restores the defaults and leaves other settings alone" do
    sign_in_as users(:one)
    @site.update!(**LIGHT, image_quality: 70)

    patch admin_settings_path, params: { reset_colors: "1", site: { image_quality: 70 } }
    assert_redirected_to edit_admin_settings_path

    @site.reload
    assert_nil @site.theme_background
    assert_nil @site.theme_text
    assert_nil @site.theme_accent
    assert_equal 70, @site.image_quality
  end

  test "anonymous visitors cannot change theme colors" do
    patch admin_settings_path, params: { site: LIGHT }

    assert_redirected_to login_path
    assert_nil @site.reload.theme_background
  end

  test "the theme preview is admin-only" do
    get theme_preview_admin_settings_path, params: { accent: "#ff0000" }
    assert_redirected_to login_path
  end

  test "the preview renders the requested colors without saving them" do
    sign_in_as users(:one)

    get theme_preview_admin_settings_path, params: { background: "#ffffff", text: "#1b1b1b", accent: "#aa3322" }
    assert_response :success
    assert_includes theme_style, "--bg:#ffffff"
    assert_includes theme_style, "--accent:#aa3322"
    assert_nil @site.reload.theme_accent, "previewing must not save"
  end

  test "the preview falls back to the saved theme for invalid colors" do
    sign_in_as users(:one)
    @site.update!(theme_accent: "#aa3322")

    get theme_preview_admin_settings_path, params: { accent: "#000;}</style><script>alert(1)</script>" }
    assert_response :success
    assert_includes theme_style, "--accent:#aa3322"
    assert_not_includes response.body, "alert(1)"
  end

  test "the preview suggests a readable color with a Use this button" do
    sign_in_as users(:one)

    get theme_preview_admin_settings_path, params: { background: "#000000", text: "#222222" }

    button = css_select(".theme-warning button[data-part='text']").first
    assert button, "no Use this button for the text color"
    suggestion = button["data-color"]
    assert_match(/\A#\h{6}\z/, suggestion)
    assert_operator Theme.contrast(suggestion, "#000000"), :>=, 4.5, "the suggestion doesn't fix the problem"
  end

  private
    def theme_style = css_select("head style").map(&:text).join
end
