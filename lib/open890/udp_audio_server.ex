defmodule Open890.UDPAudioServer do
  use GenServer
  require Logger

  alias Open890.RTP

  @port 60001
  @socket_opts [:binary, active: true]

  @udp_send_delay_ms 20

  def start_link(args) do
    Logger.info("\n\n\n*** UDP audio server: start_link\n\n\n")
    GenServer.start_link(__MODULE__, args, name: via_tuple())
    # GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  def via_tuple() do
    {:via, Registry, {:radio_connection_registry, {:udp_server}}}
  end

  def init(_args) do
    Logger.info("\n\n\n*** UDP audio server: init\n\n\n")
    {:ok, socket} = :gen_udp.open(@port, @socket_opts)
    Logger.info("UDP Audio server listening on port #{@port}")

    {:ok, tx_socket} = :gen_udp.open(@port + 1)
    Logger.info("opened UDP TX socket on #{@port + 1}")

    # timer = Process.send_after(self(), :send_packet, @udp_send_delay_ms)
    {:ok, %{socket: socket, tx_socket: tx_socket, tx_seq_num: 1, timer: nil}}
    # {:ok, %{socket: socket, tx_socket: tx_socket, tx_seq_num: 1, timer: timer}}
  end

  # def send_packet do
  #   case Registry.lookup(:radio_connection_registry, {:udp_server}) do
  #     [{pid, _}] ->
  #       send(pid, :send_packet)

  #     _ ->
  #       Logger.info("Could not find :udp_server process")
  #   end
  # end

  # def handle_info(:send_packet, state) do
  #   seq = state.tx_seq_num
  #   Logger.info("*** handle_info: :send_packet, seq: #{seq}")

  #   tx_socket = state.tx_socket

  #   bytes = Open890.VOIP.sample_payload_bytes()

  #   String.length(bytes)
  #   |> IO.inspect(label: "payload len")

  #   packet = Open890.VOIP.make_packet(seq, bytes)

  #   String.length(packet)
  #   |> IO.inspect(label: "packet len")

  #   :gen_udp.send(tx_socket, {192,168,1,106}, 60001, packet)

  #   timer = Process.send_after(self(), :send_packet, @udp_send_delay_ms)

  #   state = %{state | timer: timer, tx_seq_num: seq + 1}

  #   {:noreply, state}
  # end

  def handle_info({:udp, _udp_socket, _src_address, _dst_port, packet}, state) do
    packet
    |> RTP.parse_packet()
    |> case do
      {:ok, %RTP{payload: payload}} ->
        payload = :binary.bin_to_list(payload)
        # Logger.info("payload: #{inspect payload}")

        # Open890Web.Endpoint.broadcast("radio:audio_stream", "audio_data", %{
        #   payload: payload
        # })

        seq_num = state.tx_seq_num
        # packet = Open890.VOIP.make_packet(seq_num, payload)
        # :gen_udp.send(state.tx_socket, {192, 168, 1, 106}, 60001, packet)

        {:noreply, %{state | tx_seq_num: seq_num + 1  }}

      {:error, reason} ->
        Logger.warn("Error parsing packet: #{inspect(reason)}")
        {:noreply, state}
    end

  end
end
