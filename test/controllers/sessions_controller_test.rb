require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get login_path
    assert_response :success
  end

  test "create with valid credentials" do
    post login_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to admin_root_url
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post login_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to login_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete logout_path

    assert_redirected_to login_path
    assert_empty cookies[:session_id]
  end

  test "the login page shows the themed logo" do
    get login_path
    assert_select "svg.logo.auth__logo[role=img] g.logo-tagline", 1
  end
end
