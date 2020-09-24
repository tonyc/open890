defmodule Open890.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Open890.Repo,
      %{
        id: Open890.TCPClient,
        start: {Open890.TCPClient, :start_link, []},
        type: :supervisor
      },
      %{
        id: Open890.UDPAudioServer,
        start: {Open890.UDPAudioServer, :start_link, []},
        type: :supervisor
      },
      # Start the Telemetry supervisor
      Open890Web.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Open890.PubSub},
      # Start the Endpoint (http/https)
      Open890Web.Endpoint
      # Start a worker by calling: Open890.Worker.start_link(arg)
      # {Open890.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Open890.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Open890Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
