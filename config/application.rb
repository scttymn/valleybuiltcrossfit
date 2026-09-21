require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Valleybuilt
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Central Time (US & Canada)"

    # Photos are served through the app at one permanent address per image, marked
    # cacheable forever. The default redirects to a signed link that expires, so the
    # browser can't keep the photo and fetches it again on every reload.
    config.active_storage.resolve_model_to_route = :rails_storage_proxy

    # Send errors back through the router (ErrorsController) so a 404 looks like
    # the site — theme, fonts and logo — instead of the plain page in public/.
    config.exceptions_app = routes
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
