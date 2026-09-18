require "test_helper"

# Buttons people tap on a phone are at least 48 × 48px, whatever the screen width.
class TouchTargetsTest < ActiveSupport::TestCase
  test "the week picker's buttons are at least 48px square" do
    css = Rails.root.join("app/assets/stylesheets/site.css").read.gsub(%r{/\*.*?\*/}m, "")
    rules = css.scan(/([^{}]+)\{([^}]*)\}/).select { |selector, _| selector.split(",").any? { _1.strip == ".weeknav__btn" } }

    %w[min-width min-height].each do |property|
      values = rules.filter_map { |_, body| body[/(?:^|;)\s*#{property}:\s*(\d+)px/, 1]&.to_i }
      assert_not_empty values, ".weeknav__btn sets no #{property}"
      assert values.all? { _1 >= 48 }, ".weeknav__btn #{property} drops below 48px: #{values.inspect}"
    end
  end
end
