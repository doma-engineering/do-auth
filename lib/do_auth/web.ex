defmodule DoAuth.Web do
  @moduledoc """
  OTP subtree that takes care of things that are required for DoAuth HTTP
  backend.
  """
  use Phoenix.Endpoint, otp_app: :do_auth

  plug(Plug.Static,
    at: "/",
    from: {:do_auth, "priv/static"},
    gzip: false
  )

  plug(:not_found)

  def not_found(conn, _) do
    send_resp(conn, 404, "not found")
  end
end
