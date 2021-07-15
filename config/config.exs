# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :do_auth,
  default_root_invites: 20,
  ecto_repos: [DoAuth.Repo]

# Configures the endpoint
config :do_auth, DoAuthWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Q6jOmw0g89S+K6EnZtqo8oD944sz/kbSvwnjOHVgaThZyaGoLWrAo9H8zXavtyJt",
  render_errors: [view: DoAuthWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: DoAuth.PubSub,
  live_view: [signing_salt: "1VF8/Xx3"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
