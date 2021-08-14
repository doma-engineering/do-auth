defmodule DoAuthWeb.Users.InviteController do
  @moduledoc """
  Accept or decline invites generated either by us, or by a user to whomst a right to invite is granted.
  """

  alias DoAuth.Invite
  use DoAuthWeb, :controller
  use DoAuth.Boilerplate.DatabaseStuff

  action_fallback DoAuthWeb.FallbackController

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, %{"public" => public, "invite" => invite_presentation_map}) do
    try do
      case Invite.fulfill(public, invite_presentation_map) do
        {:ok, fulfillment} ->
          conn
          |> put_view(DoAuthWeb.Users.InviteView)
          |> render("index.json", %{fulfillment: fulfillment |> Credential.to_map()})

        {:error, e} ->
          conn |> put_status(403) |> put_view(DoAuthWeb.Users.InviteView) |> render("403.json", e)
      end
    rescue
      _e ->
        conn
        |> put_status(403)
        |> put_view(DoAuthWeb.Users.InviteView)
        |> render("403.json", %{"error" => "invalid data"})
    end
  end

  def index(conn, _) do
    conn
    |> put_status(403)
    |> put_view(DoAuthWeb.Users.InviteView)
    |> render("403.json", %{"both required" => ["public", "presentation"]})
  end
end
