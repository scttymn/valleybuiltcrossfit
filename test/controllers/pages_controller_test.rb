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

  test "schedule frame is available per week" do
    get schedule_path(week: 2)
    assert_response :success
    assert_select "turbo-frame#schedule_frame"
    assert_select "a[aria-label='Previous week'][href$='week=1']"
    # Jumping back is labelled with today's date.
    assert_select "a.weeknav__btn[href$='week=0']", text: "Today"
  end
end
