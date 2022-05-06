defmodule DoAuth.Otp.Application do
  @moduledoc """
  DoAuth servers entry point.
  """

  defp primary_children() do
    [
      %{id: DoAuth.Invite, start: {DoAuth.Invite, :start_link, [{}]}},
      %{id: DoAuth.Credential, start: {DoAuth.Credential, :start_link, [{}]}}
    ]
  end

  @spec start :: {:error, any} | {:ok, pid}
  def start() do
    start(:normal, [])
  end

  @spec start(any, any) :: {:error, any()} | {:ok, pid()} | {:ok, pid(), any()}
  def start(_start_type, _args) do
    Supervisor.start_link(primary_children(), strategy: :one_for_one, name: __MODULE__)
  end

  @spec stop() :: :ok
  def stop() do
    Supervisor.stop(__MODULE__, :normal)
  end
end
