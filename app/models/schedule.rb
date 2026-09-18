# One week (Sun–Sat, matching PushPress) of classes pulled from PushPress, cached briefly so page
# views never wait on the API.
class Schedule
  WEEK_START = :sunday # PushPress calendars start the week on Sunday
  THREADS = 6

  # How far ahead the refresh job keeps warm. PushPress returns the whole
  # horizon in one paginated pass — two months is 205 classes and 44 KB — so
  # the width of this window costs almost nothing. What costs is the reservation
  # count, which is a separate request per class, so that is what the tiered
  # refresh in RefreshScheduleJob is pacing, not the calendar itself.
  HORIZON_WEEKS = 8

  # Long enough that a week stays warm between full refreshes, so paging ahead
  # never lands on an empty cache and waits for PushPress.
  CACHE_TTL = 1.hour

  # How far past the week being viewed to warm in the background. Someone paging
  # forward usually keeps going, so the next few weeks are fetched before they
  # are asked for and the arrow never lands on a spinner.
  PREFETCH_WEEKS = 3

  Day = Data.define(:date, :classes, :workout) do
    # Any day PushPress has no classes for is a rest day.
    def rest? = classes.empty?
  end

  ClassSlot = Data.define(:id, :name, :starts_at, :ends_at, :coach, :reserved, :capacity, :register_url) do
    def open_spots = capacity && [ capacity - reserved, 0 ].max
    # Still worth a tap while the class is running — someone running late can
    # try, and PushPress applies the gym's own registration window.
    def bookable? = ends_at.future?
    def in_progress? = starts_at.past? && ends_at.future?
    def over? = ends_at.past?
  end

  attr_reader :week_start, :error

  # Offset 0 is the current week; positive offsets page ahead.
  def self.for_offset(offset, site: Site.instance)
    new(Date.current.beginning_of_week(WEEK_START) + offset.to_i.clamp(0, 52).weeks, site:)
  end

  def initialize(week_start, site: Site.instance, client: nil)
    @week_start = week_start
    @site = site
    @client = client
  end

  def days
    @days ||= begin
      slots = classes.group_by { |slot| slot.starts_at.to_date }
      workouts = Workout.where(date: dates).index_by(&:date)
      dates.map { |date| Day.new(date:, classes: slots.fetch(date, []), workout: workouts[date]) }
    end
  end

  def dates = (week_start..week_start + 6)

  # Warm the weeks just past the one being viewed, unless they are warm already.
  # This is what carries a visitor past the horizon the refresh job maintains.
  def self.prefetch_ahead(offset, site: Site.instance)
    wanted = (1..PREFETCH_WEEKS).map { |i| offset + i }.select { |o| o <= 52 }
    missing = wanted.reject { |o| for_offset(o, site:).cached? }
    return if missing.empty?

    RefreshScheduleJob.perform_later(starting: missing.min, weeks: missing.max - missing.min + 1)
  end

  # Pull several weeks in one pass and prime each week's cache, for the recurring
  # refresh job. One request covers the whole span, where a week-at-a-time loop
  # paid for the same pagination over and over.
  def self.refresh!(weeks: HORIZON_WEEKS, starting: 0, site: Site.instance, client: nil)
    first = Date.current.beginning_of_week(WEEK_START) + starting.weeks
    client ||= Pushpress::Client.new
    schedules = weeks.times.map { |offset| new(first + offset.weeks, site:, client:) }
    from = first.in_time_zone
    raw = client.classes(from:, to: from + weeks.weeks)

    by_week = raw.group_by { |c| Time.zone.at(c["start"]).to_date.beginning_of_week(WEEK_START) }
    schedules.each { |schedule| schedule.prime(by_week.fetch(schedule.week_start, [])) }
    schedules
  end

  # Turn this week's share of a horizon fetch into slots and cache them.
  def prime(raw)
    Rails.cache.write(cache_key, build_slots(raw, @client || Pushpress::Client.new), expires_in: CACHE_TTL)
  end

  def cached? = Rails.cache.exist?(cache_key)

  def cache_key = [ "schedule/v2", week_start.iso8601, @site.class_capacity, @site.uncapped_class_types ]

  private

  def classes
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL, race_condition_ttl: 30.seconds) { fetch_classes }
  rescue Pushpress::Client::Error, SocketError, Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError => e
    Rails.logger.error("[Schedule] #{e.class}: #{e.message}")
    @error = e
    []
  end

  def fetch_classes
    client = @client || Pushpress::Client.new
    from = week_start.in_time_zone
    build_slots(client.classes(from:, to: from + 7.days), client)
  end

  def build_slots(raw, client)
    counts = reservation_counts(client, raw.map { |c| c["id"] })

    raw.map do |c|
      ClassSlot.new(
        id: c["id"],
        name: c["title"].to_s.strip.presence || c["classTypeName"],
        starts_at: Time.zone.at(c["start"]),
        ends_at: Time.zone.at(c["end"]),
        coach: coach_name(client, c["coachUuid"]),
        reserved: counts.fetch(c["id"], 0),
        capacity: capped?(c["classTypeName"]) ? @site.class_capacity : nil,
        register_url: "https://#{@site.pushpress_subdomain}.pushpress.com/landing/events/#{c["id"]}"
      )
    end.sort_by(&:starts_at)
  end

  def capped?(type_name)
    return false if @site.class_capacity.blank?
    uncapped = @site.uncapped_class_types.to_s.split(",").map { |t| t.strip.downcase }
    !uncapped.include?(type_name.to_s.strip.downcase)
  end

  def reservation_counts(client, ids)
    queue = Queue.new
    ids.each { |id| queue << id }
    counts = Concurrent::Map.new
    threads = Array.new([ THREADS, ids.size ].min) do
      Thread.new do
        Rails.application.executor.wrap do
          while (id = (queue.pop(true) rescue nil))
            counts[id] = client.reservations(class_id: id).count { |r| r["status"] == "reserved" }
          end
        end
      end
    end
    ActiveSupport::Dependencies.interlock.permit_concurrent_loads { threads.each(&:join) }
    counts.each_pair.to_h
  end

  def coach_name(client, uuid)
    return nil if uuid.blank?
    (@coach_names ||= {})[uuid] ||= Rails.cache.fetch([ "pushpress/coach", uuid ], expires_in: 1.day) do
      name = client.customer(uuid)["name"] || {}
      [ name["nickname"].presence || name["first"], name["last"] ].compact_blank.join(" ")
    end
  end
end
