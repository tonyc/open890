defmodule Open890.Application do
  require Logger

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Open890.RadioConnectionRepo
  alias Open890.RadioConnection

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
    res = Supervisor.start_link(children, opts)

    display_banner()
    auto_start_connections()

    res
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Open890Web.Endpoint.config_change(changed, removed)
    :ok
  end

  def auto_start_connections do
    RadioConnection.all()
    |> Enum.filter(fn conn ->
      Map.get(conn, :auto_start, "false") == "true"
    end)
    |> Enum.each(fn conn ->
      Logger.info("Auto-starting connection id #{conn.id}, \"#{conn.name}\"")
      conn |> RadioConnection.start()
    end)
  end

  def display_banner do
    IO.puts              """
                       ___ ___  ___
   ___  ___  ___ ___  ( _ ) _ \\/ _ \\
  / _ \\/ _ \\/ -_) _ \\/ _  \\_, / // /
  \\___/ .__/\\__/_//_/\\___/___/\\___/
     /_/

  open890 is now running.
  Access the web interface at http://localhost:4000
"""
  end
end
