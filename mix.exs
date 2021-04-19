defmodule DoAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :do_auth,
      version: "0.1.0",
      elixir: "~> 1.9",
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        do_auth: [
          include_executables_for: [:unix],
          applications: [do_auth: :permanent],
          steps: [:assemble, :tar]
        ]
      ],
      aliases: aliases(),
      ### See https://hexdocs.pm/ecto/testing-with-ecto.html
      elixirc_paths: elixirc_paths(Mix.env())
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
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.2"},
      {:phoenix_html, "~> 2.14"},
      {:tzdata, "~> 1.1"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, "~> 0.15"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.1"},
      {:enacl, "~> 1.1"},
      {:typed_struct, "~> 0.2.1"},
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  ### See https://hexdocs.pm/ecto/testing-with-ecto.html
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
