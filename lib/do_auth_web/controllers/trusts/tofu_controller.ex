defmodule DoAuthWeb.Trusts.TofuController do
  use DoAuthWeb, :controller

  action_fallback DoAuthWeb.FallbackController

  @spec index(any, any) :: none
  def index(conn, _params) do
    {:ok, tofu} = DoAuth.Tofu.tofu_credential_map()
    conn |> put_view(DoAuthWeb.Trusts.TofuView) |> render("tofu.json", tofu: tofu)
  end
end
