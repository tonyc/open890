defmodule Open890Web.Live.AudioScope do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast
  alias Open890.{ConnectionCommands, RadioConnection, RadioState}
  alias Open890Web.Live.{RadioSocketState}

  alias Open890Web.Components.AudioScope
  import Open890Web.Components.Buttons

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
  def handle_info(%Broadcast{event: "scope_data", payload: %{payload: audio_scope_data}}, socket) do
    {:noreply,
     socket
     |> push_event("scope_data", %{scope_data: audio_scope_data})
     |> assign(:audio_scope_data, audio_scope_data)}
  end

  @impl true
  def handle_info(%Broadcast{event: "radio_state_data", payload: %{msg: radio_state}}, socket) do
    socket = assign(socket, :radio_state, radio_state)
    {:noreply, socket}
  end

  def handle_info(%Broadcast{} = _bc, socket) do
    {:noreply, socket}
  end

  def handle_event(event, params, socket) do
    Logger.warn("Live.AudioScope: Unknown event: #{event}, params: #{inspect(params)}")
    {:noreply, socket}
  end

end
