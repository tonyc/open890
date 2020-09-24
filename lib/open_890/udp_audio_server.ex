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
          Logger.info("UDP Sequence: #{rtp.sequence_number}")
          Logger.info(inspect(rtp.payload, pretty: true))
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
