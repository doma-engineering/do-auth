defmodule DoAuth do
  @moduledoc """
  DoAuth is a battery-included solution for high-availability distributed
  identity management.
  """

  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_, _) do
    children = [
      DoAuth.Web,
      DoAuth.Persistence,
      DoAuth.Cache
    ]

    IO.puts("Faster, leaner, and more reliable!")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
