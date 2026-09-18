require "test_helper"

class IconsControllerTest < ActionDispatch::IntegrationTest
  def favicon_fill
    Nokogiri::XML(response.body).at_css("g.logo-mark")["fill"]
  end

  test "the favicon is the logo mark in the saved accent color" do
    get favicon_path
    assert_response :success
    assert_equal "image/svg+xml", response.media_type
    assert_equal Theme::DEFAULTS[:accent], favicon_fill

    sites(:main).update!(theme_accent: "#2266aa")
    get favicon_path
    assert_equal "#2266aa", favicon_fill
  end

  test "pages link a favicon that changes with the accent, so browsers fetch the new color" do
    get root_path
    default = css_select("link[rel=icon][type='image/svg+xml']").first["href"]
    assert_equal favicon_path(v: Theme::DEFAULTS[:accent].delete("#")), default

    sites(:main).update!(theme_accent: "#2266aa")
    get login_path
    assert_select "link[rel=icon][type='image/svg+xml'][href=?]", favicon_path(v: "2266aa")
    assert_select "link[rel=icon][type='image/png'] + link[rel=icon][type='image/svg+xml']", 1, "the SVG comes last, so browsers that can show it do"
  end

  test "the current color is cached for good; a stale or missing version only briefly" do
    get favicon_path(v: Theme::DEFAULTS[:accent].delete("#"))
    assert_match(/max-age=#{1.year.to_i}/, response.headers["Cache-Control"])
    assert_includes response.headers["Cache-Control"], "public"

    [ favicon_path(v: "000000"), favicon_path ].each do |path|
      get path
      assert_equal Theme::DEFAULTS[:accent], favicon_fill, path
      assert_match(/max-age=300\b/, response.headers["Cache-Control"], path)
    end
  end

  test "a malformed stored color never reaches the icon" do
    # update_column skips validation, like a value set from the console would.
    sites(:main).update_column(:theme_accent, %("/><script>alert(1)</script>))

    get favicon_path
    assert_response :success
    assert_equal Theme::DEFAULTS[:accent], favicon_fill
    assert_not_includes response.body, "script"
  end

  test "the icon needs no sign-in and sets no cookie" do
    get favicon_path
    assert_response :success
    assert_nil response.headers["Set-Cookie"]
  end
end
