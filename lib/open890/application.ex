defmodule Open890.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Open890.RadioConnectionRepo

  @connection_registry :radio_connection_registry

  def start(_type, _args) do
    {:ok, _filename} = RadioConnectionRepo.init()

    children = [
      {Registry, [keys: :unique, name: @connection_registry]},
      # Start the Telemetry supervisor
      Open890Web.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Open890.PubSub},
      # Start the Endpoint (http/https)
      Open890Web.Endpoint,
      {Open890.RadioConnectionSupervisor,
       strategy: :one_for_one, name: Open890.RadioConnectionSupervisor}
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
