defmodule Open890Web.Live.Connections do
  require Logger

  use Open890Web, :live_view

  alias Phoenix.Socket.Broadcast

  alias Open890.RadioConnection

  def mount(_params, _session, socket) do
    Logger.info("Connections live mounted")

    connections = RadioConnection.all()

    connection_states = connections
    |> Enum.reduce(%{}, fn conn, acc ->

      state = case RadioConnection.process_exists?(conn) do
        true -> :up
        false -> :stopped
      end

      Map.put(acc, conn.id, state)
    end)

    power_states = connections
    |> Enum.reduce(%{}, fn conn, acc ->
      Map.put(acc, conn.id, :unknown)
    end)

    socket = socket
    |> assign_theme()
    |> assign(:connections, connections)
    |> assign(:connection_states, connection_states)
    |> assign(:power_states, power_states)


    if connected?(socket) do
      for c <- connections do
        Logger.info("Subscribing to connection:#{c.id}")
        Phoenix.PubSub.subscribe(Open890.PubSub, "connection:#{c.id}")
      end
    end

    {:ok, socket}
  end

  def handle_event("start_connection" = event, %{"id" => id} = params, %{assigns: assigns} = socket) do
    Logger.debug("**** ConnectionsLive: handle_event: #{event}, params: #{inspect params}")

    result = RadioConnection.start(id)

    socket = case result do
      {:ok, _conn} ->
        new_connection_states = assigns.connection_states |> Map.put(id, :up)
        socket |> assign(:connection_states, new_connection_states)
      _ ->
        Logger.warn("Could not start connection: #{inspect result}")
        socket
    end

    {:noreply, socket}
  end

  def handle_event("stop_connection" = event, %{"id" => id} = params, %{assigns: assigns} = socket) do
    Logger.debug("ConnectionsLive: handle_event: #{event}, params: #{inspect params}")

    result = id |> RadioConnection.stop()

    socket = case result do
      :ok ->
        Logger.info("stopped connection id #{id}")
        new_connection_states = assigns.connection_states |> Map.put(id, :stopped)
        new_power_states = assigns.power_states |> Map.put(id, :unknown)
        socket
        |> assign(:connection_states, new_connection_states)
        |> assign(:power_states, new_power_states)

      {:error, reason} ->
        Logger.warn("Unable to stop connection #{id}: #{inspect(reason)}")
        socket
    end

    {:noreply, socket}
  end

  def handle_event(event, params, %{assigns: _assigns} = socket) do
    Logger.debug("ConnectionsLive: default handle_event: #{event}, params: #{inspect params}")
    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "connection_state", payload: payload}, socket) do
    new_connection_states = socket.assigns.connection_states
    |> Map.put(payload.id, payload.state)

    socket = socket
    |> assign(:connection_states, new_connection_states)

    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "power_state", payload: payload}, socket) do
    new_power_states = socket.assigns.power_states
    |> Map.put(payload.id, payload.state)

    socket = socket
    |> assign(:power_states, new_power_states)

    {:noreply, socket}
  end

  # def handle_info(%Broadcast{event: "connection", payload: payload}, socket) do
  #   Logger.warn("ConnectionsLive received broadcast connection: #{inspect(payload)}")

  #   {:noreply, socket}
  # end

  def handle_info(%Broadcast{event: event, payload: payload}, socket) do
    Logger.debug("ConnectionsLive: unhandled broadcast event: #{event}, payload: #{inspect payload}")
    {:noreply, socket}
  end

  defp assign_theme(conn) do
    conn |> assign(:bg_theme, "light")
  end

end
