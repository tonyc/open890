defmodule Open890.UDPAudioServer do
  use GenServer
  require Logger

  alias Open890.RTP

  @port 60001
  @socket_opts [:binary, active: true]

  def start_link(_) do
    Logger.info("\n\n\n**** UDP AUDIO SERVER ****")
    Logger.info("*** UDP audio server: start_link")
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  def init(_args) do
    Logger.info("\n\n*** UDP audio server: init")
    {:ok, socket} = :gen_udp.open(@port, @socket_opts)

    Logger.info("UDP Audio server listening on port #{@port}")

    {:ok, %{socket: socket}}
  end

  def handle_info({:udp, _udp_socket, _src_address, _dst_port, packet}, state) do
    Logger.debug("UDPAudioServer: UDP packet")

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
