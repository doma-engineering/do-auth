defmodule DoAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :do_auth,
      version: "0.5.0-pre",
      description: "Fast, lean and reliable authentication server based on verifiable credentials standard",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
    ]
  end

  defp aliases do
    [
      test: "test --no-start",
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
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:jason, "~> 1.3"},
      {:enacl, "~> 1.2.1"},
      {:dyn_hacks, "~> 0.1.0"},
      {:uptight, "~> 0.1.0-pre1"},
      {:persist, "~> 0.1.0-pre"},
      {:doma_witchcraft, "~> 1.0.4-doma"},
      {:doma_algae, "~> 1.3.1-doma"},
      {:doma_quark, "~> 2.3.2-doma2"},
      {:plug_cowboy, "~> 2.0"},
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
