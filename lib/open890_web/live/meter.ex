defmodule Open890Web.Live.Meter do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast
  alias Open890.{ConnectionCommands, RadioConnection}
  alias Open890Web.Live.{Dispatch, RadioSocketState}

  alias Open890Web.Components.Meter

  @impl true
  def render(assigns) do
    ~H"""
      <Meter.meter s_meter={@radio_state.s_meter} alc_meter={@radio_state.alc_meter} swr_meter={@radio_state.swr_meter} />
    """
  end

  @impl true
  def mount(%{"id" => connection_id} = params, _session, socket) do
    Logger.info("LiveView mount: params: #{inspect(params)}")

    if connected?(socket) do
      RadioConnection.subscribe(Open890.PubSub, connection_id)
    end

    socket = socket |> assign(RadioSocketState.initial_state())

    socket =
      RadioConnection.find(connection_id)
      |> case do
        {:ok, %RadioConnection{} = connection} ->
          Logger.info("Found connection: #{connection_id}")

          socket = socket |> assign(:radio_connection, connection)

          socket =
            if params["debug"] do
              socket |> assign(:debug, true)
            else
              socket
            end

          socket =
            connection
            |> RadioConnection.process_exists?()
            |> case do
              true ->
                connection |> ConnectionCommands.get_initial_state()
                socket |> assign(:connection_state, :up)

              _ ->
                socket
            end

          socket

        {:error, reason} ->
          Logger.warn("Could not find radio connection id: #{connection_id}: #{inspect(reason)}")
          socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_info(%Broadcast{event: "radio_state_data", payload: %{msg: msg}}, socket) do
    socket = Dispatch.dispatch(msg, socket)

    {:noreply, socket}
  end

  # # Connection state messages
  # def handle_info(%Broadcast{event: "connection_state", payload: payload}, socket) do
  #   Logger.debug("Bandscope LV: RX connection_state: #{inspect(payload)}")

  #   {:noreply, assign(socket, :connection_state, payload)}
  # end

  def handle_info(%Broadcast{} = _bc, socket) do
    {:noreply, socket}
  end

  def handle_event(event, params, socket) do
    Logger.warn("RadioLive.Bandscope: Unknown event: #{event}, params: #{inspect(params)}")
    {:noreply, socket}
  end

end
