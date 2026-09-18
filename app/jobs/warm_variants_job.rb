# Builds every WebP size a page asks for, ahead of anyone asking for it.
#
# Active Storage generates a variant on the first request for it, inline in the
# web process. A cold page asks for a dozen at once, Puma has three threads, and
# the biggest ones — the 2000px hero, the open program card — lose the race and
# arrive at the browser as broken images. They work on a reload, which is a poor
# way to meet a first visitor.
class WarmVariantsJob < ApplicationJob
  queue_as :default
  # A missing blob means the photo was replaced while this sat in the queue.
  discard_on ActiveStorage::FileNotFoundError, ActiveRecord::RecordNotFound

  ATTACHMENTS = [
    [ Site, :hero_photo, :hero ],
    [ Program, :photo, :program ],
    [ StaffMember, :photo, :coach ]
  ].freeze

  def perform
    @built = 0

    ATTACHMENTS.each do |model, name, size|
      widths = ApplicationHelper::PHOTO_SIZES.fetch(size).fetch(:widths)
      # Owners share the staff table but render at their own size.
      widths |= ApplicationHelper::PHOTO_SIZES.fetch(:owners).fetch(:widths) if model == StaffMember

      model.find_each do |record|
        attachment = record.public_send(name)
        next unless attachment.attached?

        # A blob attached moments ago may not have been identified yet —
        # Active Storage does that in its own job, and until it has, the content
        # type is a placeholder and variable? is false. Asking here settles it
        # rather than silently skipping every photo we were enqueued to build.
        attachment.blob.identify
        next unless attachment.variable?

        widths.each { |width| warm(attachment, width) }
      end
    end

    Rails.logger.info("[variants] built #{@built} size#{"s" unless @built == 1}")
  end

  private
    def warm(attachment, width)
      variant = ApplicationController.helpers.web_variant(attachment, width)
      @built += 1 unless variant.send(:processed?)
      variant.processed
    rescue => e
      # One unreadable photo should not cost every other page its images.
      Rails.logger.warn("[variants] could not warm #{attachment.blob.filename} at #{width}px: #{e.message}")
    end
end
