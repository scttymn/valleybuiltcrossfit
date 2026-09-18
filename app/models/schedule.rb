# One week (Sun–Sat, matching PushPress) of classes pulled from PushPress, cached briefly so page
# views never wait on the API.
class Schedule
  WEEK_START = :sunday # PushPress calendars start the week on Sunday
  CACHE_TTL = 10.minutes
  THREADS = 6

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

  # Force a fresh pull from PushPress (used by the recurring refresh job).
  def refresh!
    Rails.cache.write(cache_key, fetch_classes, expires_in: CACHE_TTL)
  end

  private

  def classes
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL, race_condition_ttl: 30.seconds) { fetch_classes }
  rescue Pushpress::Client::Error, SocketError, Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError => e
    Rails.logger.error("[Schedule] #{e.class}: #{e.message}")
    @error = e
    []
  end

  def cache_key = [ "schedule/v2", week_start.iso8601, @site.class_capacity, @site.uncapped_class_types ]

  def fetch_classes
    client = @client || Pushpress::Client.new
    from = week_start.in_time_zone
    raw = client.classes(from:, to: from + 7.days)
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
