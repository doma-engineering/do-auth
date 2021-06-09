use Mix.Config

secret_key_base = "do auth test key base 123456789abcdefghijklmnopqrstuvwxyz tail 1"
signing_salt = "do auth signing salt 123456789abcdefghijklmnopqrstuvwxyz tail 12"
hash_salt = "thirty two bytes hash salt 12345"

config :do_auth, DoAuth.Web,
  secret_key_base: secret_key_base, signing_salt: signing_salt

config :do_auth, DoAuth.Crypto, hash_salt: hash_salt

config :do_auth, DoAuth.Repo, username: "phoenix", password: "VTvtqg2KG7Kz8J+UXETTfKWnaa6VNsAOoXgp8isWaViySWRns89qkyX/mmQ55Fz1"

