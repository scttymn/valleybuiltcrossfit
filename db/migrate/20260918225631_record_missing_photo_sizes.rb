class RecordMissingPhotoSizes < ActiveRecord::Migration[8.1]
  # Some photos were stored as analyzed with no width or height, so pages
  # couldn't reserve their space. Measure those once; WarmVariantsJob keeps new
  # uploads covered.
  def up
    ActiveStorage::Attachment.where(record_type: %w[Site Program StaffMember]).includes(:blob).find_each do |attachment|
      blob = attachment.blob
      next if blob.metadata.key?("width") || !blob.image?

      blob.analyze
    rescue => e
      say "could not measure #{blob.filename}: #{e.message}"
    end
  end

  def down
  end
end
