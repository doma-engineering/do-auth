use Mix.Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Credentials come from dev.secret.exs
config :do_auth, DoAuth.Repo,
  database: "do_auth_repo",
  hostname: "localhost",
  port: 5666

config :do_auth, DoAuth.Web,
  url: [host: "localhost"],
  http: [port: 8666]

config :do_auth,
  ecto_repos: [DoAuth.Repo]

import_config("dev.secret.exs")
