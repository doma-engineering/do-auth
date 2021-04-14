defmodule DoAuth do
  @moduledoc """
  DoAuth is a battery-included solution for high-availability distributed
  identity management.
  """

  require Logger
  use Application

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_, _) do
    children = [
      DoAuth.Web,
      DoAuth.Persistence,
      DoAuth.Cache
    ]

    Logger.info("Starting DoAuth v0.3: faster, leaner, and more reliable than ever.")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
