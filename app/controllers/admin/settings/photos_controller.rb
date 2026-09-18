module Admin
  module Settings
    # How uploaded photos are processed.
    class PhotosController < BaseController
      self.fields = %i[image_quality]
    end
  end
end
