require "net/http"

module Pushpress
  # Posts an inquiry to the gym's PushPress Grow workflow (an "inbound webhook"
  # trigger). The URL is a secret: anyone holding it can start the workflow, so
  # it stays server-side and out of the page.
  class Workflow
    Error = Class.new(StandardError)

    def self.url = ENV["PUSHPRESS_WEBHOOK_URL"].presence || Rails.application.credentials.dig(:pushpress, :webhook_url)
    def self.configured? = url.present?

    def self.deliver(payload)
      raise Error, "No PushPress webhook URL configured" unless configured?

      uri = URI(url)
      request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json", "Accept" => "application/json")
      request.body = payload.to_json
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 15) { _1.request(request) }

      raise Error, "PushPress webhook returned #{response.code}: #{response.body.to_s.first(200)}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    end
  end
end
