class DefaultSiteImageQuality < ActiveRecord::Migration[8.1]
  # Site.instance builds the singleton row on a fresh database, and the column
  # arrived without a default — so the row came out nil and failed its own
  # inclusion validation, taking the seeds (and every page) down with it.
  def change
    change_column_default :sites, :image_quality, from: nil, to: 80
    up_only { Site.where(image_quality: nil).update_all(image_quality: 80) }
  end
end
