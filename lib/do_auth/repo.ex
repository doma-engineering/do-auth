defmodule DoAuth.Repo do
  use Ecto.Repo,
    otp_app: :do_auth,
    adapter: Ecto.Adapters.Postgres
end
