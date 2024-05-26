defmodule Open890Web.Live.Connections do
  require Logger

  use Open890Web, :live_view

  alias Phoenix.Socket.Broadcast

  alias Open890.RadioConnection
  alias Open890.ConnectionCommands

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

    socket = socket
    |> assign_theme()
    |> assign(:connections, connections)
    |> assign(:connection_states, connection_states)


    if connected?(socket) do
      for c <- connections do
        Logger.info("Subscribing to connection:#{c.id}")
        Phoenix.PubSub.subscribe(Open890.PubSub, "connection:#{c.id}")
        # RadioConnection.subscribe(Open890.PubSub, c.id)
      end
    end

    {:ok, socket}
  end

  def handle_info(%Broadcast{event: "connection_state", payload: payload}, socket) do
    Logger.warn("ConnectionsLive received broadcast connection_state: #{inspect(payload)}")

    new_connection_states = socket.assigns.connection_states
    |> Map.put(payload.id, payload.state)

    socket = socket
    |> assign(:connection_states, new_connection_states)

    {:noreply, socket}
  end

  # def handle_info(%Broadcast{event: "connection", payload: payload}, socket) do
  #   Logger.warn("ConnectionsLive received broadcast connection: #{inspect(payload)}")

  #   {:noreply, socket}
  # end

  def handle_info(%Broadcast{event: event, payload: payload}, socket) do
    Logger.warn("ConnectionsLive: unhandled broadcast event: #{event}, payload: #{inspect payload}")
    {:noreply, socket}
  end

  defp assign_theme(conn) do
    conn |> assign(:bg_theme, "light")
  end

end
