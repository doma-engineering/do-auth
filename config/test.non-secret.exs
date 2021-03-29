use Mix.Config

secret_key_base = "do-auth-test-key-base"
signing_salt = "salt-used-by-phoenix-session"

config :do_auth, DoAuth.Web, secret_key_base: secret_key_base, signing_salt: signing_salt
