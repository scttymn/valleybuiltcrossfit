# Cloudflare Turnstile: the "verify you are human" check on the inquiry form.
# Without keys configured (development, test) it stays out of the way.
class Turnstile
  VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify".freeze
  SCRIPT_URL = "https://challenges.cloudflare.com/turnstile/v0/api.js".freeze

  class << self
    def site_key = ENV["TURNSTILE_SITE_KEY"].presence || Rails.application.credentials.dig(:turnstile, :site_key)
    def secret_key = ENV["TURNSTILE_SECRET_KEY"].presence || Rails.application.credentials.dig(:turnstile, :secret_key)
    def configured? = site_key.present? && secret_key.present?

    # Returns true when the visitor passed the check (or when it isn't set up).
    def human?(token, ip: nil)
      return true unless configured?
      return false if token.blank?

      response = Net::HTTP.post_form(URI(VERIFY_URL), { secret: secret_key, response: token, remoteip: ip }.compact)
      JSON.parse(response.body)["success"] == true
    rescue JSON::ParserError, SocketError, Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError => e
      # Cloudflare being unreachable shouldn't lose us a real inquiry.
      Rails.logger.error("[turnstile] #{e.class}: #{e.message}")
      true
    end
  end
end
