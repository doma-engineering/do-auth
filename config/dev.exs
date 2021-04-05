use Mix.Config


config :do_auth, DoAuth.Web,
  url: [host: "localhost"],
  http: [port: 8666]

config :do_auth, DoAuth.Credential,
  host: "https://aaa.doma.dev"

import_config("dev.secret.exs")
