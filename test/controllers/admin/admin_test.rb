require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  test "admin requires sign in" do
    get admin_root_path
    assert_redirected_to login_path
  end

  test "sign in lands on the dashboard" do
    post login_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to admin_root_url
  end

  test "every admin page renders" do
    sign_in_as users(:one)

    [ admin_root_path, edit_admin_site_path, edit_admin_settings_theme_path, edit_admin_settings_photos_path, edit_admin_settings_pushpress_path, edit_admin_announcement_path, admin_leads_path, admin_lead_path(leads(:sam)), admin_users_path, new_admin_user_path ].each do |path|
      get path
      assert_response :success, path
    end

    { pillars: pillars(:fitness), programs: programs(:crossfit), steps: nil, membership_options: nil, staff_members: staff_members(:chad), faqs: faqs(:fit), workouts: workouts(:monday) }.each do |name, record|
      get url_for([ :admin, name ])
      assert_response :success, "#{name} index"
      get url_for([ :new, :admin, name.to_s.singularize.to_sym ])
      assert_response :success, "#{name} new"
      next unless record
      get url_for([ :edit, :admin, record ])
      assert_response :success, "#{name} edit"
    end
  end

  test "creates, updates and deletes content" do
    sign_in_as users(:one)

    post admin_faqs_path, params: { faq: { question: "Parking?", answer: "Out front." } }
    assert_redirected_to admin_faqs_path
    faq = Faq.find_by!(question: "Parking?")
    assert_equal 2, faq.position

    patch admin_faq_path(faq), params: { faq: { answer: "Plenty out front." } }
    assert_equal "Plenty out front.", faq.reload.answer

    delete admin_faq_path(faq)
    assert_not Faq.exists?(faq.id)
  end

  test "invalid content re-renders the form" do
    sign_in_as users(:one)
    post admin_programs_path, params: { program: { name: "" } }
    assert_response :unprocessable_entity
    assert_select ".flash--alert", /Name can't be blank/
  end

  test "uploads a staff photo" do
    sign_in_as users(:one)
    photo = fixture_file_upload("coach.png", "image/png")
    patch admin_staff_member_path(staff_members(:chad)), params: { staff_member: { photo: } }
    assert staff_members(:chad).reload.photo.attached?
  end

  test "updates site content" do
    sign_in_as users(:one)
    patch admin_site_path, params: { site: { hero_title: "Show up." } }
    assert_redirected_to edit_admin_site_path
    assert_equal "Show up.", Site.instance.hero_title
  end

  test "new workout defaults to the day after the latest one" do
    sign_in_as users(:one)
    get new_admin_workout_path
    assert_select "input[name='workout[date]'][value='2026-10-06']"
  end

  test "can't remove yourself" do
    sign_in_as users(:one)
    delete admin_user_path(users(:one))
    assert User.exists?(users(:one).id)
    delete admin_user_path(users(:two))
    assert_not User.exists?(users(:two).id)
  end
end
