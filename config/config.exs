# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

if Mix.env() == :dev do
  config :mix_test_watch, clear: true
end

# Configures the endpoint
config :open890, Open890Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+EZsnAuOzfVGlj0Gh7d4qinSyI3sVfc97UM1Ppc4Tw5Gb90zLXR6GEojtVxqvd1r",
  render_errors: [view: Open890Web.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Open890.PubSub,
  live_view: [signing_salt: "vROdgs4r"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :phoenix, :trim_on_html_eex_engine, false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
