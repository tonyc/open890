defmodule Open890.UDPAudioServer do
  use GenServer
  require Logger

  alias Open890.RTP

  @port 60001
  @socket_opts [:binary, active: true]

  @udp_send_delay_ms 20

  def start_link(_) do
    Logger.info("\n\n\n*** UDP audio server: start_link\n\n\n")
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  def init(_args) do
    Logger.info("\n\n\n*** UDP audio server: init\n\n\n")
    {:ok, socket} = :gen_udp.open(@port, @socket_opts)
    Logger.info("UDP Audio server listening on port #{@port}")

    {:ok, tx_socket} = :gen_udp.open(@port + 1)
    Logger.info("opened UDP TX socket on #{@port + 1}")

    timer = Process.send_after(self(), :send_packet, @udp_send_delay_ms)
    {:ok, %{socket: socket, tx_socket: tx_socket, tx_seq_num: 1, timer: timer}}
  end

  # def send_packet do
  #   Logger.info("send_packet()")
  #   send(self(), :send_packet)
  # end

  def handle_info(:send_packet, state) do
    seq = state.tx_seq_num
    Logger.info("*** handle_info: :send_packet, seq: #{seq}")

    tx_socket = state.tx_socket

    bytes = Open890.VOIP.sample_payload_bytes()
    packet = Open890.VOIP.make_packet(seq, bytes)
    :gen_udp.send(tx_socket, {192,168,1,106}, 60001, packet)

    timer = Process.send_after(self(), :send_packet, @udp_send_delay_ms)

    state = %{state | timer: timer, tx_seq_num: seq + 1}

    {:noreply, state}
  end

  def handle_info({:udp, _udp_socket, _src_address, _dst_port, packet}, state) do
    packet
    |> RTP.parse_packet()
    |> case do
      {:ok, %RTP{} = rtp} ->
        Open890Web.Endpoint.broadcast("radio:audio_stream", "audio_data", %{
          payload: rtp.payload |> :binary.bin_to_list()
        })

      {:error, reason} ->
        Logger.warn("Error parsing packet: #{inspect(reason)}")
    end

    {:noreply, state}
  end
end
