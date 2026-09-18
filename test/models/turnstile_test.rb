require "test_helper"

class TurnstileTest < ActiveSupport::TestCase
  test "waves everyone through when it isn't configured" do
    assert_not Turnstile.configured?
    assert Turnstile.human?(nil)
  end

  test "rejects a missing token once configured" do
    with_keys { assert_not Turnstile.human?("") }
  end

  private

  def with_keys
    ENV["TURNSTILE_SITE_KEY"], ENV["TURNSTILE_SECRET_KEY"] = "site", "secret"
    yield
  ensure
    ENV.delete("TURNSTILE_SITE_KEY")
    ENV.delete("TURNSTILE_SECRET_KEY")
  end
end
