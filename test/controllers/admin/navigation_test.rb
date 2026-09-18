require "test_helper"

class Admin::NavigationTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "a menu group is open on its own pages and closed elsewhere, with the current page marked" do
    get edit_admin_settings_photos_path
    assert_select "details.nav-group[open]", 1
    assert_select "details.nav-group[open] > summary", "Settings"
    assert_select "details.nav-group[open] a.is-active", "Photos"

    get admin_root_path
    assert_select "details.nav-group[open]", 0
    assert_select "details.nav-group", minimum: 1
  end

  test "a menu group's title is a toggle, not a link" do
    get admin_root_path

    assert_select "details.nav-group > summary", "Settings"
    assert_select "details.nav-group > summary a", 0
    assert_select "details.nav-group a", text: "Theme"
    assert_select "details.nav-group a", text: "PushPress"
  end
end
