defmodule DoAuthWeb.Users.NickServController do
  @moduledoc """
  A simplistic approach to alias registrations.
  Think libera NickServ, but ten years ago :)
  """

  use DoAuthWeb, :controller
  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.NickServ

  action_fallback DoAuthWeb.FallbackController

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, %{"register" => req_map}) do
    conn = conn |> put_view(DoAuthWeb.Users.NickServView)

    try do
      case NickServ.register64(req_map) do
        {:ok, cred} -> conn |> render("index.json", %{fulfillment: cred |> Credential.to_map()})
      end

      conn |> render("index.json", ok: :ko)
    rescue
      _e ->
        conn
        |> put_status(403)
        |> render("403.json", %{"error" => "invalid data"})
    end
  end
end
