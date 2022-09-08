defmodule DoAuth.Otp.Application do
  @moduledoc """
  DoAuth servers entry point.
  """
  require Logger

  defp primary_children() do
    [
      DoAuth.Invite,
      DoAuth.Credential,
      DoAuth.Otp.UserOfa
    ]
  end

  @spec start :: {:error, any} | {:ok, pid}
  def start() do
    Logger.info("* * * * STARTING DETACHED SERVICE [1/2] * * * *")
    start(:normal, [])
  end

  @spec start(any, any) :: {:error, any()} | {:ok, pid()} | {:ok, pid(), any()}
  def start(_, [:standalone | _]) do
    Logger.info("* * * * STARTING STANDALONE SERVICE * * * *")

    Supervisor.start_link([DoAuth.Web | primary_children()],
      strategy: :one_for_one,
      name: __MODULE__
    )
  end

  def start(_start_type, _args) do
    Logger.info("* * * * STARTING DETACHED SERVICE [2/2] * * * *")
    Supervisor.start_link(primary_children(), strategy: :one_for_one, name: __MODULE__)
  end

  @spec stop() :: :ok
  def stop() do
    Supervisor.stop(__MODULE__, :normal)
  end
end
