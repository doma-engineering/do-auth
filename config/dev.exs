use Mix.Config

config :do_auth, DoAuth.Web,
  url: [host: "localhost"],
  http: [port: 8666]

import_config("dev.secret.exs")
