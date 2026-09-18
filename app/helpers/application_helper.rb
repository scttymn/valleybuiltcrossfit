module ApplicationHelper
  # The Apple and Google marks for the directions buttons (from Simple Icons,
  # CC0), drawn in the button's own color so they follow the theme.
  MAP_APP_ICONS = {
    "Apple Maps" => "M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701",
    "Google Maps" => "M12.48 10.92v3.28h7.84c-.24 1.84-.853 3.187-1.787 4.133-1.147 1.147-2.933 2.4-6.053 2.4-4.827 0-8.6-3.893-8.6-8.72s3.773-8.72 8.6-8.72c2.6 0 4.507 1.027 5.907 2.347l2.307-2.307C18.747 1.44 16.133 0 12.48 0 5.867 0 .307 5.387.307 12s5.56 12 12.173 12c3.573 0 6.267-1.173 8.373-3.36 2.16-2.16 2.84-5.213 2.84-7.667 0-.76-.053-1.467-.173-2.053H12.48z"
  }.freeze

  def map_app_icon(app)
    tag.svg(tag.path(d: MAP_APP_ICONS.fetch(app)), viewBox: "0 0 24 24", aria: { hidden: true }, focusable: "false")
  end

  # Admin-entered copy may contain simple links and line breaks.
  def rich(text)
    sanitize(text.to_s, tags: %w[a br strong em], attributes: %w[href target rel])
  end

  # How wide each photo actually renders, so we don't ship a 2000px file into a
  # 300px card. The browser picks from the widths using the sizes hint; each
  # width is roughly a layout size and its retina double.
  PHOTO_SIZES = {
    hero: { widths: [ 800, 1400, 2000 ], sizes: "(max-width: 640px) 100vw, 50vw" },
    owners: { widths: [ 440, 880 ], sizes: "(max-width: 900px) 100vw, 440px" },
    coach: { widths: [ 340, 680 ], sizes: "(max-width: 700px) 100vw, 320px" },
    program: { widths: [ 200, 440, 880 ], sizes: "(max-width: 1024px) 200px, 420px" }
  }.freeze

  # priority: for the one photo on screen when the page opens (the hero).
  # Everything else loads lazily, as the visitor scrolls toward it.
  def photo_or_placeholder(attachment, css: "photo", alt: "", size: :program, priority: false)
    # A photo that exists can still fail to load; photo_controller.js marks
    # it so it shows the missing-photo stripes instead of a broken image.
    tag.div(class: css, data: ({ controller: "photo" } if attachment.attached?)) do
      next unless attachment.attached?

      loading = priority ? { loading: "eager", fetchpriority: "high" } : { loading: "lazy" }
      widths, sizes = PHOTO_SIZES.fetch(size).values_at(:widths, :sizes)
      if attachment.variable?
        image_tag web_variant(attachment, widths.last), alt:, sizes:, **loading,
                  srcset: widths.map { |w| "#{url_for(web_variant(attachment, w))} #{w}w" }.join(", ")
      else
        image_tag attachment, alt:, **loading
      end
    end
  end

  # A resized WebP copy at the quality set in the admin.
  def web_variant(attachment, width)
    attachment.variant(resize_to_limit: [ width, width * 2 ], format: :webp, saver: { quality: Site.instance.image_quality })
  end

  def spots_label(slot, long: false)
    return (long ? "Open session — no cap" : "Open session") if slot.capacity.nil?
    return "Class full" if slot.open_spots.zero? && !long
    long ? "#{slot.reserved} of #{slot.capacity} reserved (#{slot.open_spots} open)" : "#{slot.open_spots} open"
  end

  def clock(time) = time.strftime("%-l:%M %P")
end
