require "test_helper"

class Admin::SiteContentTest < ActionDispatch::IntegrationTest
  setup { @site = sites(:main) }

  test "each section page shows only that section's fields" do
    sign_in_as users(:one)

    get edit_admin_site_section_path("hero")
    assert_response :success
    assert_select "h1", "Hero"
    assert_select "input[name='site[hero_title]']"
    assert_select "input[name='site[phone]']", 0
  end

  test "saving a section ignores fields from other sections" do
    sign_in_as users(:one)
    phone = @site.phone

    patch admin_site_section_path("hero"), params: { site: { hero_title: "Show up.", phone: "555-0100" } }

    assert_redirected_to edit_admin_site_section_path("hero")
    @site.reload
    assert_equal "Show up.", @site.hero_title
    assert_equal phone, @site.phone
  end

  test "the hero section uploads and removes the photo" do
    sign_in_as users(:one)

    patch admin_site_section_path("hero"), params: { site: { hero_title: @site.hero_title, hero_photo: fixture_file_upload("coach.png", "image/png") } }
    assert @site.reload.hero_photo.attached?

    patch admin_site_section_path("hero"), params: { site: { hero_title: @site.hero_title, remove_hero_photo: "1" } }
    assert_not @site.reload.hero_photo.attached?
  end

  test "an unknown section is not found" do
    sign_in_as users(:one)

    get edit_admin_site_section_path("pushpress")
    assert_response :not_found
    patch admin_site_section_path("nope"), params: { site: { phone: "555-0100" } }
    assert_response :not_found
  end

  test "the old site content address lands on the first section" do
    sign_in_as users(:one)

    get "/admin/site/edit"
    assert_redirected_to edit_admin_site_section_path(Admin::SitesController::SECTIONS.keys.first.parameterize)
  end

  test "anonymous visitors cannot open or save a section" do
    get edit_admin_site_section_path("hero")
    assert_redirected_to login_path

    patch admin_site_section_path("hero"), params: { site: { hero_title: "Nope" } }
    assert_redirected_to login_path
    assert_not_equal "Nope", @site.reload.hero_title
  end
end
