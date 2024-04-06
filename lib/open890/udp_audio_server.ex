defmodule Open890.UDPAudioServer do
  use GenServer
  require Logger

  alias Open890.RTP

  @socket_opts [:binary, active: true]

  def start_link(args) do
    Logger.info("UDP audio server: start_link: args: #{inspect(args)}")

    config = args |> Keyword.get(:config)

    GenServer.start_link(__MODULE__, name: __MODULE__, config: config)
  end

  def init(args) do
    Logger.info("UDP audio server: init: args: #{inspect(args)}")

    port = args |> get_in([:config, :port])

    {:ok, socket} = :gen_udp.open(port, @socket_opts)

    Logger.info("UDP Audio server listening on port #{port}")

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
