defmodule Open890Web.Live.RadioLive.Bandscope do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast
  alias Open890.RadioConnection
  alias Open890.ConnectionCommands
  alias Open890Web.Live.Dispatch
  alias Open890Web.Live.RadioSocketState
  alias Open890Web.Live.BandButtonsComponent

  # @impl true
  # def render(assigns) do
  #   Phoenix.View.render(Open890Web.RadioLiveView, "radio_live.html", assigns)
  # end

  @impl true
  def mount(%{"id" => connection_id} = params, _session, socket) do
    Logger.info("LiveView mount: params: #{inspect(params)}")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:state")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:audio_scope")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:band_scope")
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
  def handle_info(%Broadcast{event: "scope_data", payload: %{payload: audio_scope_data}}, socket) do
    {:noreply,
     socket
     |> push_event("scope_data", %{scope_data: audio_scope_data})
     |> assign(:audio_scope_data, audio_scope_data)}
  end

  @impl true
  def handle_info(
        %Broadcast{event: "band_scope_data", payload: %{payload: band_scope_data}},
        socket
      ) do
    {:noreply,
     socket
     |> push_event("band_scope_data", %{scope_data: band_scope_data})
     |> assign(:band_scope_data, band_scope_data)}
  end

  @impl true
  def handle_info(%Broadcast{event: "radio_state_data", payload: %{msg: msg}}, socket) do
    socket = Dispatch.dispatch(msg, socket)

    {:noreply, socket}
  end

  def handle_info(%Broadcast{}, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle_band_selector", _params, socket) do
    new_state = !socket.assigns.display_band_selector

    socket = assign(socket, :display_band_selector, new_state)
    {:noreply, socket}
  end
end
