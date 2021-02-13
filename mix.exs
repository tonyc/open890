defmodule Open890.MixProject do
  use Mix.Project
  @app :open890

  def project do
    [
      app: @app,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      releases: [{:open890, release()}]
    ]
  end

  defp release do
    [
      steps: [:assemble, &Bakeware.assemble/1],
      strip_beams: Mix.env() == :prod
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Open890.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bakeware, "~> 0.1.4"},
      {:credo, "~> 1.5", only: [:dev, :test]},
      {:elixir_math, "~> 0.1.2"},
      {:ecto, "~> 3.5"},
      {:excoveralls, "~> 0.13.3", only: [:dev, :test]},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:observer_cli, "~> 1.5"},
      {:phoenix, "~> 1.5"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.15"},
      {:plug_cowboy, "~> 2.0"},
      {:sobelow, "~> 0.11", only: [:dev, :test]},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:uuid, "~> 1.1.8 "}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    []
  end
end
