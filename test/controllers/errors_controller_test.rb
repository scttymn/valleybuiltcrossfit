require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  # Everything the themed page needs starts at Site.instance; take that away and
  # it stands in for the database being unreachable.
  def with_no_site
    Site.singleton_class.alias_method :working_instance, :instance
    Site.define_singleton_method(:instance) { raise "the database is gone" }
    yield
  ensure
    Site.singleton_class.alias_method :instance, :working_instance
    Site.singleton_class.remove_method :working_instance
  end

  test "a missing page comes back as a 404 dressed in the theme" do
    get "/404"

    assert_response :not_found
    assert_select "h1", "Page not found"
    assert_select ".error__code", "Error 404"
    assert_select "a.btn[href=?]", root_path
    assert_select "head style", /--accent:/, "the theme's colors are on the page"
    assert_select ".error__logo svg.logo", 1
    assert_select "footer.footer", 1
    assert_select "meta[name=robots][content=noindex]", 1
  end

  test "each error page answers with its own status and wording" do
    { "/404" => :not_found, "/422" => :unprocessable_entity, "/500" => :internal_server_error }.each do |path, status|
      get path
      assert_response status
      assert_select "h1", ErrorsController::PAGES[path.delete("/")].first
    end
  end

  test "an error on something that isn't a page is only a status" do
    get "/404", as: :json

    assert_response :not_found
    assert_predicate response.body, :blank?
  end

  test "a broken site still gets an error page rather than an error" do
    with_no_site { get "/404" }

    assert_response :internal_server_error
    assert_match "problem on our end", response.body
  end

  test "a URL that matches no route is answered by the 404 page" do
    # Tests re-raise instead of rendering an error page; this asks for the
    # production behavior, which is the only place exceptions_app is used.
    keys = %w[action_dispatch.show_exceptions action_dispatch.show_detailed_exceptions]
    original = Rails.application.env_config.values_at(*keys)
    Rails.application.env_config.merge!(keys.zip([ :all, false ]).to_h)

    get "/foo"

    assert_response :not_found
    assert_select "h1", "Page not found"
  ensure
    Rails.application.env_config.merge!(keys.zip(original).to_h)
  end
end
