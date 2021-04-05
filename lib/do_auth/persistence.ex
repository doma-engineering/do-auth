defmodule DoAuth.Persistence do
  @moduledoc """
  OTP subtree that takes care of things that are required to persist
  claims.
  """

  use Supervisor
  require Logger

  def init(_) do
    Logger.debug("Initialising #{inspect(__MODULE__)}")

    children = [
      DoAuth.Repo
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
end
