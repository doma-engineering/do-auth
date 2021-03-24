defmodule DoAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :do_auth,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        do_auth: [
          include_executables_for: [:unix],
          applications: [do_auth: :permanent],
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {DoAuth, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.5.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.1"}
    ]
  end
end
