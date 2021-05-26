defmodule DoAuth.ZeroVC.ZeroVC do
  @moduledoc """
  ZeroVC plug implementation.
  It defines API that allows:
   1. an administrator to make and revoke invites,
   2. a user to accept an invite,
   3. a user to register in a public organisation.
  """
  use Phoenix.Controller, namespace: DoAuth.Web
  # ^ be explicit to separate the modules easier later on
  import Plug.Conn
  alias DoAuth.ZeroVC.ZeroVCView, as: View

  def init(x), do: x

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(c, _) do
    c = put_session(c, :hello, "world")
    send_resp(c, 200, "put")
  end

  @spec cheer(Plug.Conn.t(), any) :: Plug.Conn.t()
  def cheer(c, _) do
    msg = get_session(c, :hello)
    c = put_session(c, :hello, msg <> msg)
    send_resp(c, 200, msg)
  end

  @spec demo(Plug.Conn.t(), any) :: Plug.Conn.t()
  def demo(c, _) do
    c |> put_view(View) |> render("demo.html", %{})
  end
end
