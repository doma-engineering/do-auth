use Mix.Config

config :do_auth, DoAuth.Web,
  url: [host: "localhost"],
  http: [port: 8666]

import_config("test.non-secret.exs")
import_config("test.secret.exs")
