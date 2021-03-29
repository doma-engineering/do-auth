use Mix.Config

secret_key_base = "do-auth-test-key-base"

config :do_auth, DoAuth.Web, secret_key_base: secret_key_base
