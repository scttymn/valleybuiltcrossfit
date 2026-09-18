# Resized copies are built on first request, inline in the web process, so a
# freshly uploaded photo makes whoever loads the page next wait for it — and
# when several arrive at once the largest ones fail outright. Building them as
# soon as the photo lands keeps that off the visitor's path.
module WarmsPhotoVariants
  extend ActiveSupport::Concern

  included do
    after_commit :warm_photo_variants, on: [ :create, :update ]
  end

  private
    def warm_photo_variants
      # The job is a no-op for sizes that already exist, so it is cheap to run
      # after any save rather than trying to detect which photo changed.
      WarmVariantsJob.perform_later
    end
end
