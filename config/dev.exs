use Mix.Config

config :do_auth, DoAuth.Web,
  url: [host: "localhost"],
  http: [port: 8666]

config :do_auth,
  ecto_repos: [DoAuth.Repo]

import_config("dev.secret.exs")
