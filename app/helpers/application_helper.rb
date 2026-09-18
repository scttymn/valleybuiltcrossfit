module ApplicationHelper
  # Each map app's own icon, in its real colors.
  MAP_APP_ICONS = { "Apple Maps" => "map-apps/apple-maps.png", "Google Maps" => "map-apps/google-maps.svg" }.freeze

  def map_app_icon(app) = MAP_APP_ICONS.fetch(app)

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
