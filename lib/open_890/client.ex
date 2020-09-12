defmodule Open890.Client do
  use GenServer
  require Logger

  @socket_opts [:binary, active: true]
  @tcp_port 60000
  # @udp_recv_port 60001

  alias Open890.RTP
  alias Open890.KNS

  def start_link(_args) do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  def init(_args) do
    radio_ip_address = System.fetch_env!("RADIO_IP_ADDRESS") |> String.to_charlist()
    radio_username = System.fetch_env!("RADIO_USERNAME")
    radio_password = System.fetch_env!("RADIO_PASSWORD")
    radio_user_is_admin = (System.fetch_env("RADIO_USER_IS_ADMIN") == "true")

    {:ok, socket} = :gen_tcp.connect(radio_ip_address, @tcp_port, @socket_opts)
    # {:ok, incoming_udp_socket} = :gen_udp.open(@udp_recv_port, @socket_opts)

    kns_user = KNS.User.build()
      |> KNS.User.username(radio_username)
      |> KNS.User.password(radio_password)
      |> KNS.User.is_admin(radio_user_is_admin)

    send(self(), :radio_login)

    {:ok,
      %{
        socket: socket,
        kns_user: kns_user,
        audio_scope_data: List.duplicate(0, 50)
      }
    }
  end

  # Client API
  def send_command(cmd) do
    GenServer.cast(__MODULE__, {:send_cmd, cmd})
  end

  # Server API
  def handle_cast({:send_cmd, cmd}, %{socket: socket} = state) do
    socket |> send_command(cmd)
    {:noreply, state}
  end

  # networking

  def handle_info({:tcp, socket, msg}, %{socket: socket} = state) do
    Logger.info("<- #{inspect msg}")

    new_state = msg
    |> String.split(";")
    |> Enum.reject(& &1 == "")
    |> Enum.reduce(state, fn single_message, acc ->
      handle_msg(single_message, acc)
    end)

    {:noreply, new_state}
  end

  def handle_info({:tcp_closed, socket}, state) do
    Logger.error("TCP socket closed: #{inspect socket}")

    {:noreply, state}
  end

  def handle_info({:udp, _udp_socket, _src_address, _dst_port, packet}, state) do
    RTP.parse_packet(packet)
    |> case do
      {:ok, %RTP{} = rtp} ->
        if rem(rtp.sequence_number, 500) == 0 do
          Logger.debug("UDP Sequence: #{rtp.sequence_number}")
          # Logger.debug(inspect(rtp, pretty: true))
        end

      {:error, reason} ->
        Logger.warn("Error parsing packet: #{inspect reason}")
    end

    {:noreply, state}
  end

  # radio commands

  def handle_info(:enable_voip, %{socket: socket} = state) do
    socket |> send_command("##VP2")

    {:noreply, state}
  end

  def handle_info(:radio_login, %{socket: socket} = state) do
    socket |> send_command("##CN")
    {:noreply, state}
  end

  def handle_info(:send_keepalive, %{socket: socket} = state) do
    schedule_ping()

    socket |> send_command("PS")

    {:noreply, state}
  end

  # radio responses
  def handle_msg("##CN1", %{socket: socket, kns_user: kns_user} = state) do
    login = KNS.User.to_login(kns_user)

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
    # Logger.info("received TI1, enabling voip")
    # send(self(), :enable_voip)
    state
  end

  def handle_msg("PS1", state), do: state
  def handle_msg("##UE1", state), do: state

  def handle_msg(msg, %{socket: _socket} = state) when is_binary(msg) do
    cond do
      msg |> String.starts_with?("##DD3") ->
        %{state | audio_scope_data: parse_audioscope_data((msg))}

      true ->
        Logger.warn("Unhandled message: #{inspect msg}")
        state
    end
  end

  # def send_udp(socket, msg) when is_binary(msg) do
  #   Logger.debug("SEND_UDP ->" <> msg)
  #   :gen_udp.send(socket, '127.0.0.1', 60001, msg)
  # end

  defp schedule_ping do
    Process.send_after(self(), :send_keepalive, 5000)
  end

  defp send_command(socket, msg) when is_binary(msg) do
    cmd = msg <> ";"

    Logger.info("-> #{inspect cmd}")

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
      (-val) + 50
    end)
  end
end
