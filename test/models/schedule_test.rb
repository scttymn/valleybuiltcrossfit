require "test_helper"

class ScheduleTest < ActiveSupport::TestCase
  SUNDAY = Date.new(2026, 10, 4) # weeks run Sun–Sat, like PushPress
  MONDAY = SUNDAY + 1
  SATURDAY = SUNDAY + 6

  def at(date, hour, min = 0) = Time.zone.local(date.year, date.month, date.day, hour, min).to_i

  def fake
    FakePushpress.new(
      classes: [
        { "id" => "cal-1", "title" => "CrossFit ", "classTypeName" => "CrossFit", "coachUuid" => "usr_j", "start" => at(MONDAY, 5), "end" => at(MONDAY, 6) },
        { "id" => "cal-2", "title" => "CrossFit", "classTypeName" => "CrossFit", "coachUuid" => "usr_j", "start" => at(MONDAY, 6), "end" => at(MONDAY, 7) },
        { "id" => "cal-3", "title" => "Open Build", "classTypeName" => "General", "coachUuid" => nil, "start" => at(SATURDAY, 7, 30), "end" => at(SATURDAY, 10, 30) },
        { "id" => "cal-next", "title" => "CrossFit", "classTypeName" => "CrossFit", "start" => at(MONDAY + 7, 5), "end" => at(MONDAY + 7, 6) }
      ],
      reservations: { "cal-1" => [ { "status" => "reserved" }, { "status" => "reserved" }, { "status" => "cancelled" } ] },
      customers: { "usr_j" => { "name" => { "first" => "Jessica", "last" => "Isaacson", "nickname" => "" } } }
    )
  end

  def weekdays(days) = days.map { _1.date.strftime("%a") }

  test "groups a Sunday–Saturday week of PushPress classes by day with open spots" do
    client = fake
    days = Schedule.new(SUNDAY, site: sites(:main), client:).days

    assert_equal %w[Sun Mon Tue Wed Thu Fri Sat], weekdays(days)
    assert_equal [ "cal-1", "cal-2" ], days[1].classes.map(&:id)

    first = days[1].classes.first
    assert_equal "CrossFit", first.name
    assert_equal "Jessica Isaacson", first.coach
    assert_equal 2, first.reserved, "cancelled reservations don't count"
    assert_equal 16, first.open_spots
    assert_equal "https://valleybuiltcrossfit.pushpress.com/landing/events/cal-1", first.register_url
    assert_equal 1, client.customer_calls, "coach lookups are memoized"
  end

  test "uncapped class types have no capacity and next week's classes are excluded" do
    days = Schedule.new(SUNDAY, site: sites(:main), client: fake).days

    open_build = days[6].classes.sole
    assert_nil open_build.capacity
    assert_nil open_build.coach
    assert days[0].rest?
    assert_not days.flat_map(&:classes).map(&:id).include?("cal-next")
  end

  test "every day of the week is shown, and days without classes are rest days" do
    days = Schedule.new(SUNDAY, site: sites(:main), client: fake).days
    assert_equal %w[Sun Mon Tue Wed Thu Fri Sat], weekdays(days)
    assert_equal [ true, false, true, true, true, true, false ], days.map(&:rest?)
  end

  test "a class stays bookable until it ends, and is marked in progress while it runs" do
    days = Schedule.new(SUNDAY, site: sites(:main), client: fake).days
    five_am = days[1].classes.first # 5:00–6:00 am

    travel_to Time.zone.local(2026, 10, 5, 4, 59) do
      assert five_am.bookable?
      assert_not five_am.in_progress?
      assert_not five_am.over?
    end

    travel_to Time.zone.local(2026, 10, 5, 5, 30) do
      assert five_am.bookable?, "running late is still worth a try"
      assert five_am.in_progress?, "it runs until 6am"
      assert_not five_am.over?
    end

    travel_to Time.zone.local(2026, 10, 5, 6, 1) do
      assert_not five_am.bookable?
      assert_not five_am.in_progress?
      assert five_am.over?
    end
  end

  test "attaches workouts by date" do
    days = Schedule.new(SUNDAY, site: sites(:main), client: fake).days
    assert_equal workouts(:monday), days[1].workout
    assert_nil days[2].workout
  end

  test "an unreachable API yields an empty schedule with the error" do
    schedule = Schedule.new(SUNDAY, site: sites(:main), client: broken_client)
    assert schedule.days.all?(&:rest?)
    assert_equal "boom", schedule.error.message
  end

  test "offset zero is the current week (starting Sunday) and offsets page ahead" do
    site = sites(:main)

    travel_to Date.new(2026, 9, 17) do
      assert_equal Date.new(2026, 9, 13), Schedule.for_offset(0, site:).week_start
      assert_equal SUNDAY, Schedule.for_offset(3, site:).week_start
      assert_equal Date.new(2026, 9, 13), Schedule.for_offset(-3, site:).week_start
    end
    travel_to Date.new(2026, 9, 20) do # a Sunday starts its own week
      assert_equal Date.new(2026, 9, 20), Schedule.for_offset(0, site:).week_start
    end
  end

  private

  def broken_client
    Object.new.tap { |client| def client.classes(**) = raise(Pushpress::Client::Error, "boom") }
  end
end
