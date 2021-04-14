use Mix.Config

config :do_auth, DoAuth.Web,
  url: [host: "localhost"],
  http: [port: 8666]

config :do_auth, DoAuth.Repo, database: "do_auth_test", pool: Ecto.Adapters.SQL.Sandbox

import_config("test.non-secret.exs")
import_config("test.secret.exs")
