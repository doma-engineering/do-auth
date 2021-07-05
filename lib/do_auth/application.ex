defmodule DoAuth.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      DoAuth.Repo,
      # Start the Telemetry supervisor
      DoAuthWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: DoAuth.PubSub},
      # Start the Endpoint (http/https)
      DoAuthWeb.Endpoint,
      ## Start a worker by calling: DoAuth.Worker.start_link(arg)
      # {DoAuth.Worker, arg}

      # This is kind of an ugly one. Sorry.
      %{
        id: DoAuth.Repo.Populate,
        start: {DoAuth.Repo.Populate, :populate, []},
        restart: :transient
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DoAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DoAuthWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
