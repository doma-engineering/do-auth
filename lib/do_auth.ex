defmodule DoAuth do
  @moduledoc """
  DoAuth is a battery-included solution for high-availability distributed
  identity management.
  """

  use Application

  def start(_, _) do
    children = [
      DoAuth.Web,
      DoAuth.Persistence,
      DoAuth.Session
    ]

    IO.puts("Faster, leaner, and more reliable!")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
