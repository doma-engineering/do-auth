use Mix.Config

## A snippet from some artefact under `~/dummy` on our plausible server.
# secret_key_base =
#  System.get_env("SECRET_KEY_BASE") ||
#    raise """
#    environment variable SECRET_KEY_BASE is missing.
#    You can generate one by calling: mix phx.gen.secret
#    """
## It's a nice approach that we should migrate to later on, but for the time
## being it feels fine to just put secrets into .gitignored file

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Credentials come from dev.secret.exs
config :do_auth, DoAuth.Repo,
  database: "do_auth_repo",
  hostname: "localhost",
  port: 5666

config :do_auth, DoAuth.Web,
  url: [host: "aaa.doma.dev"],
  http: [port: 8696],
  secret_key_base: secret_key_base

import_config("prod.secret.exs")
