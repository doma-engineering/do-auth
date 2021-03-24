defmodule DoAuth.Session do
  @moduledoc """
  OTP subtree that concerns:
   - Session management for non-atomic client interactions as
     challenge-response "registration" protocol.
   - Server-side caching of any object that we don't want to store in or
     read from the database.
  """

  use Supervisor

  def init(_) do
    IO.inspect(__MODULE__)
    Supervisor.init([], strategy: :one_for_one)
  end

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
end
