use Mix.Config

secret_key_base = "do auth test key base 123456789abcdefghijklmnopqrstuvwxyz tail 1"
signing_salt = "do auth signing salt 123456789abcdefghijklmnopqrstuvwxyz tail 12"
hash_salt = "thirty two bytes hash salt 12345"

config :do_auth, DoAuth.Web, secret_key_base: secret_key_base, signing_salt: signing_salt

config :do_auth, DoAuth.Crypto,
  hash_salt: hash_salt,
  server_keypair: %{
    public:
      <<196, 32, 166, 36, 137, 39, 40, 96, 191, 83, 23, 16, 117, 237, 48, 216, 144, 130, 252, 0,
        227, 242, 122, 201, 103, 99, 10, 223, 134, 134, 84, 147>>,
    secret:
      <<116, 169, 57, 180, 48, 45, 29, 121, 102, 151, 192, 69, 26, 67, 112, 135, 224, 98, 132,
        127, 118, 144, 51, 242, 29, 201, 119, 209, 92, 199, 70, 61, 196, 32, 166, 36, 137, 39, 40,
        96, 191, 83, 23, 16, 117, 237, 48, 216, 144, 130, 252, 0, 227, 242, 122, 201, 103, 99, 10,
        223, 134, 134, 84, 147>>
  }
