defmodule DoAuth.ZeroVC.Controller do
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

  def init(x), do: x

  def index(c, _) do
    IO.puts("Calling index")
    send_resp(c, 200, "index")
  end

  def cheer(c, _) do
    IO.puts("Calling cheer")
    send_resp(c, 200, "are you a'right luv")
  end
end
