use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :do_auth, DoAuth.Repo,
  username: "postgres",
  password: "postgres",
  database: "do_auth_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  port: 5666,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :do_auth, DoAuthWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

import_config("test.non-secret.exs")
import_config("test.secret.exs")
