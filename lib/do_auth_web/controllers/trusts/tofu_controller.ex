defmodule DoAuthWeb.Trusts.TofuController do
  @moduledoc """
  Controller for DoAutho servers to introduce themselves.
  """
  use DoAuthWeb, :controller

  action_fallback DoAuthWeb.FallbackController

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, _params) do
    {:ok, tofu} = DoAuth.Tofu.tofu_credential_map()
    conn |> put_view(DoAuthWeb.Trusts.TofuView) |> render("tofu.json", tofu: tofu)
  end
end
