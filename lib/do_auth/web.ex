defmodule DoAuth.Web do
  @moduledoc """
  The thing that launches cowboy and stuff.

  Only used when the application is ran in standalone mode.any()

  TODO: Validate that this doesn't get ran when DoAuth is used as a dependency.
  """

  use Supervisor
  require Logger
  alias Uptight.Text, as: T

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

  @spec default_host :: T.t()
  def default_host() do
    Application.get_env(:do_auth, __MODULE__) |> Keyword.get(:host, "localhost") |> T.new!()
  end

  @spec default_port() :: number()
  def default_port() do
    Application.get_env(:do_auth, __MODULE__) |> Keyword.get(:port, 8110)
  end

  @spec default_opts :: keyword(T.t() | list(T.t()))
  def default_opts() do
    [
      homebase:
        Application.get_env(:do_auth, __MODULE__)
        |> Keyword.get(:front_host, "localhost")
        |> T.new!(),
      port:
        Application.get_env(:do_auth, __MODULE__)
        |> Keyword.get(:front_port, 3001)
        |> to_string()
        |> T.new!(),
      front_name:
        Application.get_env(:do_auth, __MODULE__)
        |> Keyword.get(:front_name, "do auth")
        |> T.new!(),
      endpoint:
        Application.get_env(:do_auth, __MODULE__)
        |> Keyword.get(:front_endpoint, ["confirm"])
        |> Enum.map(&T.new!/1)
    ]
  end
end
