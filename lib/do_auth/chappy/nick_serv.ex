defmodule DoAuth.Chappy.NickServ do
  @moduledoc """
  Basically a nickserv.
  """

  use Phoenix.Controller, namespace: DoAuth.Web
  alias DoAuth.Chappy.NickServView, as: View
  alias DoAuth.NickServ

  # TODO: Since we're speedrunning this shit, we're really ifgnoring the fact
  # that we need to actually sign registration request on client! It needs to be
  # fixed.

  # DRY
  def reg(c, _) do
    {:ok, nick_cert} = NickServ.register64(c.body_params["did"], c.body_params["nickname"], false)
    c |> put_view(View) |> render("register.json", %{nick_cert: nick_cert})
  end

  # DRY
  def cloak(c, _) do
    {:ok, nick_cert} = NickServ.register64(c.body_params["did"], c.body_params["nickname"], true)
    c |> put_view(View) |> render("register.json", %{nick_cert: nick_cert})
  end
end
