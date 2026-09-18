# Resized copies are built on first request, inline in the web process, so a
# freshly uploaded photo makes whoever loads the page next wait for it — and
# when several arrive at once the largest ones fail outright. Building them as
# soon as the photo lands keeps that off the visitor's path.
module WarmsPhotoVariants
  extend ActiveSupport::Concern

  included do
    # attachment_changes is only populated while the save is in flight, so note
    # it there and act once the file is actually committed to storage. Without
    # the check every edit to a name or a bio would queue a job with no work.
    before_save { @photo_changed = attachment_changes.any? }
    after_commit :warm_photo_variants, on: [ :create, :update ]
  end

  private
    def warm_photo_variants
      WarmVariantsJob.perform_later if @photo_changed
      @photo_changed = false
    end
end
