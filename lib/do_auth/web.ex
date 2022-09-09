defmodule DoAuth.Web do
  @moduledoc """
  The thing that launches cowboy and stuff.

  Only used when the application is ran in standalone mode.any()

  TODO: Validate that this doesn't get ran when DoAuth is used as a dependency.
  """

  use Supervisor
  require Logger

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  # @spec init(any) :: {:ok, {%{intensity: any, period: any, strategy: any}, list}}
  def init(_) do
    do_auth_port = Application.get_env(:do_auth, __MODULE__) |> Keyword.get(:port, 8110)

    children = [
      {Plug.Cowboy, scheme: :http, plug: DoAuth.Router, port: do_auth_port}
    ]

    opts = [strategy: :one_for_one]

    Supervisor.init(children, opts)
  end

  def default_host() do
    # TODO: make this configurable
    Uptight.Text.new!("localhost")
  end

  def default_port() do
    Application.get_env(:do_auth, __MODULE__) |> Keyword.get(:port, 8110)
  end
end
