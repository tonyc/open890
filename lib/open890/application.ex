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

    udp_config = Application.get_env(:open890, Open890.UDPAudioServer)

    children = [
      {Registry, [keys: :unique, name: @connection_registry]},
      # Start the Telemetry supervisor
      Open890Web.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Open890.PubSub},
      # Start the Endpoint (http/https)
      Open890Web.Endpoint,
      {Open890.RadioConnectionSupervisor,
       strategy: :one_for_one, name: Open890.RadioConnectionSupervisor},
      {Open890.CloudlogSupervisor, strategy: :one_for_one, name: Open890.CloudlogSupervisor},
      {Open890.UDPAudioServer, [config: udp_config]}
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
    url_config = Application.get_env(:open890, Open890Web.Endpoint)[:url]

    host = url_config[:host] || "localhost"
    port = url_config[:port] || "4000"

    IO.puts("""
                           ___ ___  ___
       ___  ___  ___ ___  ( _ ) _ \\/ _ \\
      / _ \\/ _ \\/ -_) _ \\/ _  \\_, / // /
      \\___/ .__/\\__/_//_/\\___/___/\\___/
         /_/

      open890 is now running.  Press ^C^C (ctrl-c, ctrl-c) to stop.

      Access the web interface at http://#{host}:#{port}/

      You can change the hostname, web, and UDP audio ports by setting OPEN890_HOST,
      OPEN890_PORT, and OPEN890_UDP_PORT environment variables respectively.
    """)
  end
end
