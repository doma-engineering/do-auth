defmodule DoAuthWeb.Users.NickServController do
  @moduledoc """
  A simplistic approach to alias registrations.
  Think libera NickServ, but ten years ago :)
  """

  use DoAuthWeb, :controller

  action_fallback DoAuthWeb.FallbackController

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, _params) do
    conn |> put_view(DoAuthWeb.Users.NickServView) |> render("index.json", ok: :ko)
  end
end
