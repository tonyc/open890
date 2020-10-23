defmodule Open890.TCPClient do
  use GenServer
  require Logger

  @socket_opts [:binary, active: true]
  @port 60000

  @enable_audio_scope true
  @enable_band_scope true

  alias Open890.KNS.User

  def start_link() do
    Logger.info("************** START_LINK")
    GenServer.start_link(__MODULE__, [], name: :radio)
  end

  @impl true
  def init(_args) do
    radio_ip_address = System.fetch_env!("RADIO_IP_ADDRESS") |> String.to_charlist()
    radio_username = System.fetch_env!("RADIO_USERNAME")
    radio_password = System.fetch_env!("RADIO_PASSWORD")
    radio_user_is_admin = System.fetch_env("RADIO_USER_IS_ADMIN") == "true"

    kns_user =
      User.build()
      |> User.username(radio_username)
      |> User.password(radio_password)
      |> User.is_admin(radio_user_is_admin)

    self() |> send(:connect_socket)

    {:ok,
     %{
       radio_ip_address: radio_ip_address,
       kns_user: kns_user
     }}
  end

  # Client API
  def ch_up, do: "CH0" |> cmd()
  def ch_down, do: "CH1" |> cmd()

  def radio_up(args \\ "03") when is_binary(args), do: "UP#{args}" |> cmd()
  def radio_down(args \\ "03") when is_binary(args), do: "DN#{args}" |> cmd()

  def freq_change(:up) do
    ("FC0" <> freq_change_step()) |> cmd()
  end

  def freq_change(:down) do
    ("FC1" <> freq_change_step()) |> cmd()
  end

  def vfo_a_b_swap, do: "EC" |> cmd()
  def get_vfo_a_freq, do: "FA" |> cmd()
  def get_vfo_b_freq, do: "FB" |> cmd()
  def get_active_receiver, do: "FR" |> cmd()
  def get_band_scope_limits, do: "BSM0" |> cmd()
  def get_band_scope_mode, do: "BS3" |> cmd()

  # TODO: Make this configurable
  defp freq_change_step, do: "5"

  def cmd(cmd) do
    Logger.info("#{__MODULE__}.send_command(#{inspect(cmd)})")
    GenServer.cast(:radio, {:send_command, cmd})
  end

  # Server API
  @impl true
  def handle_cast({:send_command, cmd}, state) do
    Logger.info("handle_cast: send_command: #{cmd}")
    state.socket |> send_command(cmd)
    {:noreply, state}
  end

  # networking
  @impl true
  def handle_info({:tcp, socket, msg}, %{socket: socket} = state) do
    # Logger.info("<- #{inspect msg}")

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
    Logger.warn("TCP socket closed. State: #{inspect(state)}")

    {:noreply, state}
  end

  def handle_info(:connect_socket, state) do
    {:ok, socket} = :gen_tcp.connect(state.radio_ip_address, @port, @socket_opts)

    Logger.info("Established TCP socket with radio on port #{@port}")

    self() |> send(:login_radio)

    {:noreply, state |> Map.put(:socket, socket)}
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
    # Logger.info("Enabling HQ VOIP stream")
    # state.socket |> send_command("##VP1") # high quality
    # state.socket |> send_command("##VP2") # low quality


    {:noreply, state}
  end

  def handle_info(:query_active_receiver, state) do
    state.socket |> send_command("FR")
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

  # radio responses
  def handle_msg("##CN1", %{socket: socket, kns_user: kns_user} = state) do
    login = User.to_login(kns_user)

    socket |> send_command("##ID" <> login)
    state
  end

  # Logged in
  def handle_msg("##ID1", state) do
    Logger.info("signed in, scheduling first ping")
    schedule_ping()
    state
  end

  # Sent at the very end of the login sequence,
  # Finally OK to enable VOIP
  def handle_msg("##TI1", %{socket: _socket} = state) do
    Logger.info("received TI1")
    # send(self(), :enable_voip)

    if @enable_audio_scope, do: send(self(), :enable_audioscope)
    if @enable_band_scope, do: send(self(), :enable_bandscope)
    send(self(), :enable_auto_info)
    send(self(), :query_active_receiver)

    state
  end

  def handle_msg("PS1", state), do: state
  def handle_msg("##UE1", state), do: state
  def handle_msg("DD01", state), do: state
  def handle_msg("DD11", state), do: state

  def handle_msg("FR0" = msg, state) do
    msg |> broadcast()
    state
  end

  def handle_msg("FR1" = msg, state) do
    msg |> broadcast()
    state
  end

  def handle_msg(msg, %{socket: _socket} = state) when is_binary(msg) do
    cond do
      msg |> String.starts_with?("##DD3") ->
        audio_scope_data = msg |> parse_audioscope_data()

        # len = audio_scope_data |> Enum.count()
        # Logger.info("Audio scope data length: #{len}")

        Open890Web.Endpoint.broadcast("radio:audio_scope", "scope_data", %{
          payload: audio_scope_data
        })

        state

      msg |> String.starts_with?("##DD2") ->
        band_scope_data = msg |> parse_bandscope_data()

        # len = band_scope_data |> Enum.count()
        # Logger.info("Band scope data length: #{len}")

        Open890Web.Endpoint.broadcast("radio:band_scope", "band_scope_data", %{
          payload: band_scope_data
        })

        state

      msg |> String.starts_with?("BS3") ->
        msg |> broadcast()
        state

      msg |> String.starts_with?("BSM0") ->
        msg |> broadcast()
        state

      msg |> String.starts_with?("SM") ->
        msg |> broadcast()
        state

      msg |> String.starts_with?("FA") || msg |> String.starts_with?("FB") ->
        msg |> broadcast()
        state

      true ->
        Logger.warn("Unhandled message: #{inspect(msg)}")
        state
    end
  end

  defp broadcast(msg) do
    Open890Web.Endpoint.broadcast("radio:state", "radio_state_data", %{msg: msg})
  end

  defp schedule_ping do
    Process.send_after(self(), :send_keepalive, 5000)
  end

  defp send_command(socket, msg) when is_binary(msg) do
    cmd = msg <> ";"

    if cmd != "PS;", do: Logger.debug("-> #{inspect(cmd)}")

    socket |> :gen_tcp.send(cmd)

    socket
  end

  defp parse_audioscope_data(msg) do
    msg
    |> String.trim_leading("##DD3")
    |> String.codepoints()
    |> Enum.chunk_every(2)
    |> Enum.map(&Enum.join/1)
    |> Enum.map(fn value ->
      val = Integer.parse(value, 16) |> elem(0)
      -val + 50
    end)
  end

  defp parse_bandscope_data(msg) do
    msg
    |> String.trim_leading("##DD2")
    |> String.codepoints()
    |> Enum.chunk_every(2)
    |> Enum.map(&Enum.join/1)
    |> Enum.map(fn value ->
      val = Integer.parse(value, 16) |> elem(0)
      val
      # -val + 140
    end)
  end
end
