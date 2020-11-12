defmodule Open890.UDPAudioServer do
  use GenServer
  require Logger

  alias Open890.RTP

  @port 60001
  @socket_opts [:binary, active: true]

  def start_link() do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  def init(_args) do
    {:ok, socket} = :gen_udp.open(@port, @socket_opts)

    Logger.info("UDP Audio server listening on port #{@port}")

    {:ok, %{socket: socket}}
  end

  def handle_info({:udp, _udp_socket, _src_address, _dst_port, packet}, state) do
    packet
    |> RTP.parse_packet()
    |> case do
      {:ok, %RTP{} = rtp} ->
        payload = rtp.payload |> Base.encode64()
        Open890Web.Endpoint.broadcast("radio:audio_stream", "audio_data", %{payload: payload})

        if rem(rtp.sequence_number, 500) == 0 do
          packet_chunked =
            rtp.payload
            |> :binary.bin_to_list()
            |> Enum.chunk_every(2)
            |> Enum.map(fn bytes -> :binary.list_to_bin(bytes) end)
            |> Enum.map(fn word ->
              <<sample::signed-16>> = word
              sample / 32767
            end)

          chunked_length = packet_chunked |> Enum.count()

          Logger.info(
            "Packet chunked to samples length: #{chunked_length} (#{inspect(packet_chunked)})"
          )

          # packet |> IO.inspect(label: "PACKET", limit: :infinity)
          raw_packet_length = packet |> String.length()
          packet_binary_length = packet |> :binary.bin_to_list() |> Enum.count()
          payload_length = rtp.payload |> :binary.bin_to_list() |> Enum.count()

          Logger.info(
            "UDP Sequence: #{rtp.sequence_number}, received #{payload_length} bytes, UDP binary length: #{
              packet_binary_length
            }, packet string len: #{raw_packet_length} "
          )

          # Logger.info(inspect(rtp.payload, pretty: true))
        end

      {:error, reason} ->
        Logger.warn("Error parsing packet: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  # defp send_udp(socket, msg) when is_binary(msg) do
  #   Logger.debug("SEND_UDP ->" <> msg)
  #   :gen_udp.send(socket, '127.0.0.1', 60001, msg)
  # end
end
