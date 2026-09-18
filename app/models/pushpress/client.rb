require "net/http"

# Thin wrapper around the PushPress Platform API (v3).
module Pushpress
  class Client
    BASE_URL = "https://api.pushpress.com/v3".freeze
    PAGE_SIZE = 100
    Error = Class.new(StandardError)
    # The email already belongs to a PushPress account (theirs are global, so
    # this happens even when the gym has no such customer).
    DuplicateEmail = Class.new(Error)

    def initialize(api_key: self.class.api_key)
      raise Error, "PushPress API key is not configured" if api_key.blank?
      @api_key = api_key
    end

    def self.api_key
      ENV["PUSHPRESS_API_KEY"].presence || Rails.application.credentials.dig(:pushpress, :api_key)
    end

    # PushPress only filters on a start bound, so page forward in start order
    # and stop once we're past `to`.
    def classes(from:, to:)
      params = { startsAfter: from.to_i - 1, order: "ascending" }
      paginate("/classes", params) { |batch| batch.last && batch.last["start"] >= to.to_i }
        .select { |c| c["start"] >= from.to_i && c["start"] < to.to_i }
    end

    def reservations(class_id:)
      paginate("/reservations", calendarItemId: class_id)
    end

    def customer(id)
      get("/customers/#{id}")
    end

    # Creates a contact in PushPress, which is what the gym's "contact created"
    # workflow listens for. Returns the new customer id.
    def create_customer(email:, first_name:, last_name: nil, phone: nil)
      body = {
        email: email,
        name: { first: first_name, last: last_name.presence || first_name, nickname: nil },
        phone: phone.presence,
        source: "PLATFORM"
      }.compact

      post("/customers", body)["id"]
    end

    private

    def paginate(path, params, &done)
      (1..).each_with_object([]) do |page, results|
        batch = get(path, params.merge(limit: PAGE_SIZE, page: page)).dig("data", "resultArray") || []
        results.concat(batch)
        break results if batch.size < PAGE_SIZE || done&.call(batch)
      end
    end

    def post(path, body)
      uri = URI("#{BASE_URL}#{path}")
      request = Net::HTTP::Post.new(uri, "API-KEY" => @api_key, "Accept" => "application/json", "Content-Type" => "application/json")
      request.body = body.to_json
      send_request(uri, request, path)
    end

    def get(path, params = {})
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?
      request = Net::HTTP::Get.new(uri, "API-KEY" => @api_key, "Accept" => "application/json")
      send_request(uri, request, path)
    end

    def send_request(uri, request, path)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) { |http| http.request(request) }
      raise DuplicateEmail, response.body.to_s.first(200) if response.code == "409"
      raise Error, "PushPress #{path} returned #{response.code}: #{response.body.to_s.first(200)}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
end
