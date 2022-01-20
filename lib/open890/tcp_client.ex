defmodule Open890.TCPClient do
  use GenServer
  require Logger

  @socket_opts [:binary, active: true, exit_on_close: true, send_timeout: 1000, send_timeout_close: true]
  @connect_timeout_ms 5000

  @enable_audio_scope true
  @enable_band_scope true

  alias Open890.{ConnectionCommands, RadioConnection, RadioState}
  alias Open890.KNS.User

  def start_link(%RadioConnection{id: id} = args) do
    GenServer.start_link(__MODULE__, args, name: via_tuple(id))
  end

  def via_tuple(connection_id) do
    {:via, Registry, {:radio_connection_registry, {:tcp, connection_id}}}
  end

  @impl true
  def init(%RadioConnection{} = connection) do
    radio_username = connection.user_name
    radio_password = connection.password
    radio_user_is_admin = connection.user_is_admin

    kns_user =
      User.build()
      |> User.username(radio_username)
      |> User.password(radio_password)
      |> User.is_admin(radio_user_is_admin)

    send(self(), :connect_socket)

    {:ok,
      %{
        connection: connection,
        kns_user: kns_user,
        radio_state: %RadioState{}
      }}
  end

  @impl true
  def handle_call(:get_radio_state, _from, state) do
    {:reply, {:ok, state.radio_state}, state}
  end

  # Server API
  @impl true
  def handle_cast({:send_command, cmd}, state) do
    state.socket |> send_command(cmd)
    {:noreply, state}
  end

  def handle_info({:tcp, _socket, _msg}, {:noreply, state}) do
    Logger.error("Got TCP :noreply")

    broadcast_connection_state(state.connection, {:down, :tcp_noreply})
    {:stop, :shutdown, state}
  end

  # networking
  @impl true
  def handle_info({:tcp, socket, msg}, %{socket: socket} = state) do
    new_state =
      msg
      |> String.split(";")
      |> Enum.reject(&(&1 == ""))
      |> Enum.reduce(state, fn single_message, acc ->
        handle_msg(single_message, acc)
      end)

    {:noreply, new_state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.warn("TCP socket closed.")

    broadcast_connection_state(state.connection, {:down, :tcp_closed})

    {:stop, :shutdown, state}
  end

  def handle_info(:connect_socket, state) do
    ip_address = state.connection.ip_address |> String.to_charlist()
    tcp_port = RadioConnection.tcp_port(state.connection)

    :gen_tcp.connect(ip_address, tcp_port, @socket_opts, @connect_timeout_ms)
    |> case do
      {:ok, socket} ->
        Logger.info("Established TCP socket with radio on port #{tcp_port}")
        broadcast_connection_state(state.connection, :up)
        self() |> send(:login_radio)
        {:noreply, state |> Map.put(:socket, socket)}

      {:error, reason} ->
        broadcast_connection_state(state.connection, {:down, reason})
        Logger.error("Unable to connect to radio: #{inspect(reason)}. Connection: #{inspect(state.connection)}")

        {:stop, :shutdown, state}
    end
  end

  def handle_info(:login_radio, %{socket: socket} = state) do
    socket |> send_command("##CN")
    {:noreply, state}
  end

  # radio commands
  def handle_info(:enable_audioscope, %{socket: socket} = state) do
    Logger.info("Enabling audio scope via LAN")
    socket |> send_command("DD11")

    {:noreply, state}
  end

  def handle_info(:enable_bandscope, %{socket: socket} = state) do
    Logger.info("Enabling LAN bandscope")

    # low cycle
    # socket |> send_command("DD03")

    # medium-cycle
    # socket |> send_command("DD02")

    # high-cycle
    socket |> send_command("DD01")

    {:noreply, state}
  end

  def handle_info(:enable_voip, state) do
    Logger.info("\n\n**** Enabling HQ VOIP stream\n\n")
    state.socket |> send_command("##VP1") # high quality
    # state.socket |> send_command("##VP2") # low quality

    {:noreply, state}
  end

  def handle_info(:query_active_receiver, state) do
    state.socket |> send_command("FR")
    {:noreply, state}
  end

  def handle_info(:get_initial_state, %{connection: connection} = state) do
    connection |> ConnectionCommands.get_initial_state()
    {:noreply, state}
  end

  def handle_info(:enable_auto_info, state) do
    state.socket |> send_command("AI2")
    {:noreply, state}
  end

  def handle_info(:send_keepalive, %{socket: socket} = state) do
    schedule_ping()

    socket |> send_command("PS")

    {:noreply, state}
  end

  def handle_msg("##CN0", %{socket: socket} = state) do
    msg = "Unable to connect to radio: The KNS connection may already be in use by another application"

    Logger.warn(msg)
    broadcast_connection_state(state.connection, {:down, :kns_in_use})

    {:noreply, socket}
  end

  # connection allowed response
  def handle_msg("##CN1", %{socket: socket, kns_user: kns_user} = state) do
    login = kns_user |> User.to_login()

    socket |> send_command("##ID" <> login)
    state
  end

  # login successful response
  def handle_msg("##ID1", state) do
    Logger.info("signed in, scheduling first ping")
    schedule_ping()

    if @enable_audio_scope, do: send(self(), :enable_audioscope)
    if @enable_band_scope, do: send(self(), :enable_bandscope)

    send(self(), :enable_auto_info)
    send(self(), :query_active_receiver)
    send(self(), :get_initial_state)

    state
  end

  # Incorrect username/password
  def handle_msg("##ID0", %{connection: connection} = state) do
    Logger.warn("Error connecting to radio: Incorrect username or password")
    broadcast_connection_state(connection, {:down, :bad_credentials})

    {:stop, :shutdown, state}
  end

  # power status respnose
  def handle_msg("PS1", state) do
    # TODO: Cancel the connection timer here
    state
  end

  # login enabled response
  def handle_msg("##UE1", state), do: state

  # everything under here

  # # bandscope data speed high response
  # def handle_msg("DD01", state), do: state

  # # filter scope LAN/high cycle respnose
  # def handle_msg("DD11", state), do: state

  def handle_msg("PS0", state) do
    {:noreply, state}
    # {:stop, :normal, state}
  end

  def handle_msg("BSD", %{connection: connection} = state) do
    RadioConnection.broadcast_band_scope_cleared(connection)

    state
  end

  def handle_msg(msg, %{socket: _socket, connection: connection, radio_state: radio_state} = state) when is_binary(msg) do
    cond do
      # high speed filter/audio scope response
      msg |> String.starts_with?("##DD3") ->
        audio_scope_data =
          msg
          |> String.trim_leading("##DD3")
          |> parse_scope_data()

        RadioConnection.broadcast_audio_scope(connection, audio_scope_data)

        state

      # high speed band scope data response
      msg |> String.starts_with?("##DD2") ->
        band_scope_data =
          msg
          |> String.trim_leading("##DD2")
          |> parse_scope_data()

        RadioConnection.broadcast_band_scope(connection, band_scope_data)

        state

      true ->
        # otherwise, broadcast the new radio state to the liveview
        if !(msg |> String.starts_with?("SM0")) do
          Logger.info("[DN] #{inspect(msg)}")
        end

        radio_state = RadioState.dispatch(msg, radio_state)

        if ["FA", "FB", "OM0", "FT"] |> Enum.any?(&String.starts_with?(msg, &1)) do
          Open890.Cloudlog.update(connection, radio_state)
        end

        if (msg |> String.starts_with?("FA") && radio_state.active_receiver == :a) ||
          (msg |> String.starts_with?("FB") && radio_state.active_receiver == :b) do

          if radio_state.band_scope_edges do
            {low, high} = radio_state.band_scope_edges
            delta = radio_state.active_frequency_delta
            active_receiver = radio_state.active_receiver

            RadioConnection.broadcast_freq_delta(connection, %{
              delta: delta,
              vfo: active_receiver,
              bs: %{low: low, high: high}
            })
          end
        end

        RadioConnection.broadcast_radio_state(connection, radio_state)
        %{state | radio_state: radio_state}
    end
  end

  def broadcast_connection_state(%RadioConnection{} = connection, state) do
    RadioConnection.broadcast_connection_state(connection, state)
  end

  defp schedule_ping do
    Process.send_after(self(), :send_keepalive, 5000)
  end

  defp send_command(socket, msg) when is_binary(msg) do
    cmd = msg <> ";"

    if cmd != "PS;", do: Logger.info("[UP] #{inspect(cmd)}")

    socket |> :gen_tcp.send(cmd)

    socket
  end

  defp parse_scope_data(msg) do
    msg
    |> String.codepoints()
    |> Enum.chunk_every(2)
    |> Enum.map(&Enum.join/1)
    |> Enum.map(fn value ->
      Integer.parse(value, 16) |> elem(0)
    end)
  end
end
