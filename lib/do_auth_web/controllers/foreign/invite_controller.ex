defmodule DoAuthWeb.Foreign.InviteController do
  use DoAuthWeb, :controller
  use DoAuth.Boilerplate.DatabaseStuff

  alias DoAuth.Repo.Populate

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, _params) do
    conn = conn |> put_view(DoAuthWeb.Foreign.InviteView)

    try do
      root = Populate.ensure_root_invite!() |> Credential.to_map()
      conn |> render("index.json", %{root: root})
    rescue
      _e ->
        conn
        |> put_status(500)
        |> render("500.json", %{"error" => "failed to retrieve the root invite"})
    end
  end
end
