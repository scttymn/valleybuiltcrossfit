require "test_helper"

class Pushpress::ClientTest < ActiveSupport::TestCase
  # Serves canned pages instead of making HTTP requests.
  class PagedClient < Pushpress::Client
    attr_reader :requests

    def initialize(pages)
      super(api_key: "test")
      @pages, @requests = pages, []
    end

    private

    def get(path, params = {})
      @requests << [ path, params ]
      { "data" => { "resultArray" => @pages.fetch(params[:page] - 1, []) } }
    end
  end

  def page(starts) = starts.map { |s| { "id" => "cal-#{s}", "start" => s } }

  test "classes pages forward from startsAfter and stops once past the range" do
    full = Pushpress::Client::PAGE_SIZE
    client = PagedClient.new([ page((1..full).to_a), page((full + 1..2 * full).to_a), page([ 999_999 ]) ])

    result = client.classes(from: 50, to: 150)

    assert_equal (50...150).to_a, result.map { _1["start"] }
    assert_equal 2, client.requests.size, "doesn't fetch pages after the range"
    assert_equal({ startsAfter: 49, order: "ascending", limit: full, page: 1 }, client.requests.first.last)
  end

  test "requires an API key" do
    assert_raises(Pushpress::Client::Error) { Pushpress::Client.new(api_key: nil) }
  end
end
