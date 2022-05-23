defmodule DoAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :do_auth,
      version: "0.5.2-pre",
      description:
        "Fast, lean and reliable authentication server based on verifiable credentials standard",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      propcheck: [counter_examples: "counter_examples"],
      # dev
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true,
        remove_defaults: [:unknown]
      ]
    ]
  end

  defp aliases do
    [
      # test: "test --no-start"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DoAuth.Otp.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:propcheck, "~> 1.4.1", only: [:test, :dev], runtime: true},
      {:jason, "~> 1.3"},
      {:enacl, "~> 1.2.1"},
      {:dyn_hacks, "~> 0.1.0"},
      {:uptight, "~> 0.2.6-rc"},
      {:persist, "~> 0.1.2-rc"},
      {:doma, "~> 1.0.0"},
      {:doma_witchcraft, "~> 1.0.4-doma"},
      {:doma_algae, "~> 1.3.1-doma"},
      {:doma_quark, "~> 2.3.2-doma2"},
      {:plug_cowboy, "~> 2.0"},
      {:bamboo_smtp, "~> 4.1"}
    ]
  end

  defp package do
    [
      licenses: ["WTFPL"],
      links: %{
        "GitHub" => "https://github.com/doma-engineering/do-auth",
        "Support" => "https://social.doma.dev/@jonn",
        "Matrix" => "https://matrix.to/#/#uptight:matrix.org"
      },
      maintainers: ["doma.dev"]
    ]
  end
end
