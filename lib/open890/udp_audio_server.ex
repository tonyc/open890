defmodule Open890.UDPAudioServer do
  use GenServer
  require Logger

  alias Open890.RTP

  @port 60001
  @socket_opts [:binary, active: true]

  def start_link(args) do
    Logger.info("\n\n\n*** UDP audio server: start_link\n\n\n")
    # GenServer.start_link(__MODULE__, args, name: via_tuple())
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  def via_tuple() do
    {:via, Registry, {:radio_connection_registry, {:udp_server}}}
  end

  def init(_args) do
    Logger.info("\n\n\n*** UDP audio server: init\n\n\n")
    {:ok, socket} = :gen_udp.open(@port, @socket_opts)
    Logger.info("UDP Audio server listening on port #{@port}")

    {:ok, %{socket: socket}}
  end

  def handle_info({:udp, _udp_socket, _src_address, _dst_port, packet}, state) do
    packet
    |> RTP.parse_packet()
    |> case do
      {:ok, %RTP{payload: payload}} ->
        Open890Web.Endpoint.broadcast("radio:audio_stream", "audio_data", %{
          payload: :binary.bin_to_list(payload)
        })

        {:noreply, state}

      {:error, reason} ->
        Logger.warn("Error parsing packet: #{inspect(reason)}")
        {:noreply, state}
    end

  end
end
