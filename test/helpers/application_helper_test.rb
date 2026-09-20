require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # One shape for every photo in a section, taken from the photos themselves, so
  # a set of upright photos isn't cropped to a letterbox — and one odd photo
  # among them can't decide the shape for the rest.
  test "photo shape follows the middle shape of the photos" do
    { [ [ 480, 720 ], [ 480, 720 ], [ 700, 700 ] ] => "4 / 5",      # mostly upright
      [ [ 700, 700 ], [ 700, 700 ], [ 480, 720 ] ] => "1 / 1",      # mostly square
      [ [ 1920, 1080 ], [ 1440, 800 ], [ 700, 700 ] ] => "3 / 2",   # mostly wide
      [ [ 1000, 1000 ] ] => "1 / 1" }.each do |sizes, shape|
      assert_equal shape, photo_shape(sizes.map { |w, h| fake_photo(w, h) }), sizes.inspect
    end
  end

  test "photos with no size recorded, and no photos at all, fall back to wide" do
    assert_equal "3 / 2", photo_shape([])
    assert_equal "3 / 2", photo_shape([ fake_photo(nil, nil) ])
    assert_equal "4 / 5", photo_shape([ fake_photo(nil, nil), fake_photo(480, 720) ]), "one known photo decides"
  end

  private
    def fake_photo(width, height)
      metadata = width && height ? { "width" => width, "height" => height } : {}
      Struct.new(:attached?, :blob).new(true, Struct.new(:metadata).new(metadata))
    end
end
