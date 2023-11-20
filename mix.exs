defmodule Open890.MixProject do
  use Mix.Project
  @app :open890

  def version, do: "0.0.0-dev"

  def project do
    [
      app: @app,
      version: version(),
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
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
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.11"},
      {:httpoison, "~> 1.8.0"},
      {:jason, "~> 1.0"},
      {:mix_test_watch, "~> 1.0", only: [:dev], runtime: false},
      {:phoenix, "~> 1.7.7", override: true},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19.5"},
      {:phoenix_view, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:toml, "~> 0.6.2"},
      {:uniq, "~> 0.5"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "assets.deploy": [
        "esbuild default --minify",
        "cmd assets/node_modules/.bin/postcss assets/css/app.scss --output priv/static/css/app.css --verbose --parser postcss-scss --config assets --use postcss-advanced-variables postcss-nested autoprefixer",
        "phx.digest"
      ],
      "assets.deploy.windows": [
        "esbuild default --minify",
        "cmd assets\\node_modules\\.bin\\postcss assets\\css\\app.scss --output priv\\static\\css\\app.css --verbose --parser postcss-scss --config assets --use postcss-advanced-variables postcss-nested autoprefixer",
        "phx.digest"
      ]
    ]
  end
end
