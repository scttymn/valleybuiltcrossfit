require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home renders every section from the database" do
    get root_path

    assert_response :success
    assert_select "h1", text: /Come as you are/
    %w[programs expect schedule dropin membership coaches visit].each { |id| assert_select "section##{id}" }
    assert_select ".program-card", 2
    assert_select ".program-card[aria-expanded=true]", 1
    assert_select ".program-detail:not([hidden])", 1
    assert_select ".owners h3", "Jessica & Greg Isaacson"
    assert_select ".coach h3", "Chad Worman"
    assert_select ".faq h3", "Do I need to be fit to start?"
    assert_select "form[action='#{leads_path}']"
    # The simple version by default: a question, with nothing else pre-chosen.
    assert_select "input[name='lead[interest]'][value='#{Lead::QUESTION}'][checked]"
    assert_select "input[name='lead[starting_from]'][checked]", 0
    assert_select "input[name='lead[who]'][checked]", 0
  end

  test "schedule still renders when PushPress is unavailable" do
    get root_path
    assert_select ".schedule-notice", /couldn't load the live schedule/
  end

  test "days without classes show as rest days, including Sunday" do
    get root_path
    assert_select ".week .day", 7
    assert_select ".week .day:first-child .day__dow", "Sun"
    assert_select ".week .slot--closed", text: "Rest day", count: 7
    assert_select ".picker__day", 7
  end

  test "days without a WOD show a disabled No WOD marker in place of the button" do
    get root_path
    assert_select ".week .day__head .day__wod--none", text: "No WOD", count: 7
    assert_select ".picker .picker__wod--none", text: "No WOD posted", count: 7
    assert_select "button.day__wod", 0
  end

  test "today's column is highlighted in the current week" do
    get root_path
    assert_select ".week .day--today", 1
    assert_select ".week .day--today .day__dow", text: "Today"
    assert_select ".week .day--today .day__date", text: Date.current.strftime("%b %-d")
    assert_select ".picker__day--today", 1

    get schedule_path(week: 1)
    assert_select ".day--today", 0, "only the current week has today in it"
  end

  test "the week picker keeps every control in place on the current week" do
    get root_path
    assert_select ".weeknav .weeknav__btn", 3
    assert_select ".weeknav__btn--arrow[aria-disabled=true]", 1, "no paging back before this week"
    assert_select ".weeknav__btn[aria-disabled=true]", text: "Today"
    assert_select "a.weeknav__btn--arrow[aria-label='Next week']", 1
  end

  test "the announcement bar shows, links and hides" do
    site = sites(:main)

    get root_path
    assert_select ".announce", text: site.announcement

    site.update!(announcement_url: "https://example.com/holiday-hours")
    get root_path
    assert_select "a.announce[href='https://example.com/holiday-hours']", text: site.announcement

    site.update!(announcement_visible: false)
    get root_path
    assert_select ".announce", 0
  end

  test "the header's Book an intro is the same filled button as the hero's" do
    get root_path

    assert_select "nav a.btn.btn--primary", text: "Book an intro"
    assert_select ".hero a.btn.btn--primary"
    assert_select ".nav__cta", 0
  end

  test "the hero photo loads first; every other photo waits until it's near" do
    sites(:main).hero_photo.attach(io: Rails.root.join("db/seed_images/hero.webp").open, filename: "hero.webp")
    programs(:crossfit).photo.attach(io: Rails.root.join("db/seed_images/crossfit.webp").open, filename: "crossfit.webp")

    get root_path
    assert_select ".hero__photo img[loading=eager][fetchpriority=high]"
    assert_select ".program-card .photo img[loading=lazy]"
    assert_select ".program-card .photo img[fetchpriority]", 0
  end

  test "photos have one stable address the browser can keep, so a reload doesn't fetch them again" do
    sites(:main).hero_photo.attach(io: Rails.root.join("db/seed_images/hero.webp").open, filename: "hero.webp")

    get root_path
    img = css_select(".hero__photo img").first
    urls = [ img["src"], *img["srcset"].split(", ").map { _1.split.first } ]
    urls.each { |url| assert_match %r{/rails/active_storage/representations/proxy/}, url, "a redirect URL expires and changes" }

    get URI(img["src"]).path
    assert_response :success
    assert_equal "image/webp", response.media_type
    cache = response.headers["Cache-Control"]
    assert_includes cache, "public"
    assert_includes cache, "immutable"
    assert_operator cache[/max-age=(\d+)/, 1].to_i, :>=, 1.year.to_i

    get root_path
    assert_equal img["src"], css_select(".hero__photo img").first["src"], "the address changed between page loads"
  end

  test "a photo that could fail to load is watched; a missing one needs no watching" do
    sites(:main).hero_photo.attach(io: Rails.root.join("db/seed_images/hero.webp").open, filename: "hero.webp")

    get root_path
    assert_select ".hero__photo.photo[data-controller=photo] img"
    assert_select ".program-card .photo:not([data-controller])", minimum: 1
  end

  test "fonts come from the site itself, and the ones above the fold load first" do
    get root_path

    assert_no_match %r{fonts\.(googleapis|gstatic)\.com}, response.body, "fonts still load from Google"
    preloads = css_select("link[rel=preload][as=font]")
    assert_operator preloads.size, :>=, 1
    preloads.each do |link|
      assert_equal "font/woff2", link["type"]
      assert link.key?("crossorigin"), "a font preload without crossorigin is fetched twice"
    end
  end

  test "the map is drawn by the site at the gym's location, not embedded from Google" do
    get root_path

    assert_select ".visit__map[data-controller=map][data-map-latitude-value='39.0251858'][data-map-longitude-value='-94.2158759']"
    assert_select "iframe", 0
    assert_no_match %r{maps\.google\.com/maps\?.*output=embed}, response.body
    script = Rails.root.join("app/javascript/controllers/map_controller.js").read
    library = script[%r{LIBRARY = "(/vendor/maplibre-gl-[\d.]+/)"}, 1]
    assert library, "the map controller doesn't load MapLibre from the site"
    %w[maplibre-gl.mjs maplibre-gl-shared.mjs maplibre-gl-worker.mjs maplibre-gl.css].each do |file|
      assert Rails.public_path.join(library.delete_prefix("/"), file).file?, "#{library}#{file} is missing"
    end
  end

  test "without a location there is no map, and directions still work" do
    sites(:main).update!(map_latitude: nil, map_longitude: nil)

    get root_path
    assert_select ".visit__map", 0
    assert_select ".directions a", 2
  end

  test "get directions lets the visitor pick Apple Maps or Google Maps instead of assuming one" do
    get root_path

    assert_select ".directions summary", text: "Get directions"
    assert_select ".directions a[target=_blank][rel~=noopener]", 2
    [ "Apple Maps", "Google Maps" ].each { |app| assert_select ".directions a", text: app }
  end

  test "theme-color matches the palette background" do
    get root_path
    assert_select "meta[name='theme-color'][content=?]", Theme.default.variables["--bg"]
  end

  test "the page declares the theme colors in a style tag" do
    get root_path

    style = css_select("head style").map(&:text).join
    Theme.default.variables.each do |token, value|
      assert_includes style, "#{token}:#{value}", "#{token} is missing from the page"
    end
  end

  test "a malformed stored color never reaches the style tag" do
    # update_column skips validation, like a value set from the console would.
    sites(:main).update_column(:theme_accent, "#000;}</style><script>alert(1)</script>")

    get root_path
    assert_response :success
    assert_includes css_select("head style").map(&:text).join, "--accent:#{Theme::DEFAULTS[:accent]}"
    assert_not_includes response.body, "alert(1)"
  end

  test "schedule frame is available per week" do
    get schedule_path(week: 2)
    assert_response :success
    assert_select "turbo-frame#schedule_frame"
    assert_select "a[aria-label='Previous week'][href$='week=1']"
    # Jumping back is labelled with today's date.
    assert_select "a.weeknav__btn[href$='week=0']", text: "Today"
  end
end
