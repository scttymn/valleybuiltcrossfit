require "test_helper"

# The fonts are served from the site, one file per family per character range.
class FontsTest < ActiveSupport::TestCase
  FONTS = Rails.root.join("app/assets/fonts")

  test "every font file the stylesheet names is there" do
    names = Rails.root.join("app/assets/stylesheets/fonts.css").read.scan(/url\("([^"]+)"\)/).flatten
    assert_not_empty names
    names.each { |name| assert FONTS.join(name).file?, "fonts.css names #{name}, which is missing" }
  end

  test "no two character ranges share a file" do
    # Yellowtail's basic-latin file was once a copy of its latin-ext file, which
    # has only accented letters, so the script line quietly fell back to another font.
    FONTS.glob("*.woff2").group_by { Digest::SHA256.file(_1).hexdigest }.each_value do |files|
      assert_equal 1, files.size, "the same file under two names: #{files.map(&:basename).join(', ')}"
    end
  end
end
