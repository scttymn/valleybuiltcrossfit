require "test_helper"

class Admin::SettingsTest < ActionDispatch::IntegrationTest
  setup { @site = sites(:main) }

  test "each settings page ignores fields that belong to another" do
    sign_in_as users(:one)
    before = @site.slice(:image_quality, :class_capacity, :theme_accent)

    patch admin_settings_theme_path, params: { site: { theme_accent: "#aa3322", image_quality: 55, class_capacity: 99 } }
    assert_redirected_to edit_admin_settings_theme_path
    @site.reload
    assert_equal "#aa3322", @site.theme_accent
    assert_equal before.values_at("image_quality", "class_capacity"), [ @site.image_quality, @site.class_capacity ]

    patch admin_settings_photos_path, params: { site: { image_quality: 65, theme_accent: "#123456", class_capacity: 99 } }
    assert_redirected_to edit_admin_settings_photos_path
    @site.reload
    assert_equal [ 65, "#aa3322", before["class_capacity"] ], [ @site.image_quality, @site.theme_accent, @site.class_capacity ]

    patch admin_settings_pushpress_path, params: { site: { class_capacity: 20, image_quality: 40, theme_accent: "#123456" } }
    assert_redirected_to edit_admin_settings_pushpress_path
    @site.reload
    assert_equal [ 20, 65, "#aa3322" ], [ @site.class_capacity, @site.image_quality, @site.theme_accent ]
  end

  test "image quality stays within sensible bounds" do
    sign_in_as users(:one)

    patch admin_settings_photos_path, params: { site: { image_quality: 5 } }
    assert_response :unprocessable_entity
    assert_equal 80, @site.reload.image_quality
  end

  test "the old settings address lands on the theme page" do
    sign_in_as users(:one)

    get "/admin/settings/edit"
    assert_redirected_to edit_admin_settings_theme_path
    get "/admin/settings"
    assert_redirected_to edit_admin_settings_theme_path
  end

  test "anonymous visitors cannot open or save any settings page" do
    [ edit_admin_settings_theme_path, edit_admin_settings_photos_path, edit_admin_settings_pushpress_path, preview_admin_settings_theme_path ].each do |path|
      get path
      assert_redirected_to login_path, path
    end

    patch admin_settings_photos_path, params: { site: { image_quality: 60 } }
    assert_redirected_to login_path
    assert_equal 80, @site.reload.image_quality
  end

  test "the chat widget is set on the PushPress page, and stays off the admin" do
    sign_in_as users(:one)

    get edit_admin_settings_pushpress_path
    assert_select "input[name='site[chat_widget_id]']"
    patch admin_settings_pushpress_path, params: { site: { chat_widget_id: "" } }
    assert_nil @site.reload.chat_widget_id.presence

    @site.update!(chat_widget_id: "6aadb116599f010aecda2679")
    [ edit_admin_settings_pushpress_path, preview_admin_settings_theme_path ].each do |path|
      get path
      assert_select "[data-controller=chat]", 0, path
    end
  end
end
