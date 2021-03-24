defmodule DoAuth.Persistence do
  @moduledoc """
  OTP subtree that takes care of things that are required to persist
  claims.
  """

  use Supervisor

  def init(_) do
    IO.inspect(__MODULE__)
    Supervisor.init([], strategy: :one_for_one)
  end

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
end
