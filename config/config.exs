import Config

config :do_auth, ecto_repos: [DoAuth.Repo]

config :phoenix, :json_library, Jason

# Usage example
config :do_auth, DoAuth.Web, vc_plug: DoAuth.ZeroVC.Plug

# http://www.petecorey.com/blog/2019/05/20/minimum-viable-phoenix/ thank you, Pete!
import_config "#{Mix.env()}.exs"
