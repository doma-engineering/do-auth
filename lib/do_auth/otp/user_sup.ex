defmodule DoAuth.Otp.UserSup do
  @moduledoc """
  DynamicSupervisor that starts a per-user process that allocate nicknames and E-Mails addresses.

  Verify that it works in iex:
    Task.async(fn -> start_bucket(T.new!("Hello"), T.new!("World")) end)
    start_bucket(T.new!("Hello"), T.new!("World"))
  """

  use DynamicSupervisor

  alias Uptight.Text, as: T

  def start_bucket(%T{} = email, %T{} = nickname) do
    DynamicSupervisor.start_child(__MODULE__, {DoAuth.User, [email, nickname]})
  end

  def start_link(initx) do
    DynamicSupervisor.start_link(__MODULE__, initx, name: __MODULE__)
  end

  @impl true
  def init(_initx) do
    # TODO: Add persist, polling all the users and restarting them before we signal that Sup initialisation is finished
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
