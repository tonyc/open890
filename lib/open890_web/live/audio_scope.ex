defmodule Open890Web.Live.AudioScope do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast
  alias Open890.{ConnectionCommands, Extract, RadioConnection}
  alias Open890Web.Live.{Dispatch, RadioSocketState}

  alias Open890Web.Components.AudioScope


  # @impl true
  # def render(assigns) do
  #   Phoenix.View.render(Open890Web.RadioLiveView, "radio_live.html", assigns)
  # end

  @impl true
  def mount(%{"id" => connection_id} = params, _session, socket) do
    Logger.info("LiveView mount: params: #{inspect(params)}")

    if connected?(socket) do
      RadioConnection.subscribe(Open890.PubSub, connection_id)
    end

    socket = socket |> assign(RadioSocketState.initial_state())

    socket =
      with {:ok, file} <- File.read("config/config.toml"),
           {:ok, config} <- Toml.decode(file) do
        macros = config |> get_in(["ui", "macros"]) || []
        socket |> assign(:__ui_macros, macros)
      else
        reason ->
          Logger.warn(
            "Could not load config/config.toml: #{inspect(reason)}. This is not currently an error."
          )

          socket
      end

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
  def handle_info(%Broadcast{event: "radio_state_data", payload: %{msg: msg}}, socket) do
    socket = Dispatch.dispatch(msg, socket)

    {:noreply, socket}
  end

  # Connection state messages
  def handle_info(%Broadcast{event: "connection_state", payload: payload}, socket) do
    Logger.debug("Bandscope LV: RX connection_state: #{inspect(payload)}")

    {:noreply, assign(socket, :connection_state, payload)}
  end

  # def handle_info(%Broadcast{event: "radio_info", payload: %{level: level, msg: msg}}, socket) do
  #   Logger.info("***** radio_info: [#{level}] msg: #{inspect(msg)}")
  #   {:noreply, put_flash(socket, level, msg)}
  # end

  def handle_info(%Broadcast{} = _bc, socket) do
    {:noreply, socket}
  end

  # received by Task.async
  def handle_info({_ref, :ok}, socket) do
    {:noreply, socket}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, socket) do
    {:noreply, socket}
  end

  def handle_event(event, params, socket) do
    Logger.warn("RadioLive.Bandscope: Unknown event: #{event}, params: #{inspect(params)}")
    {:noreply, socket}
  end

  defp close_modals(socket) do
    socket |> assign(display_band_selector: false, display_screen_id: 0)
  end

  def radio_classes(debug \\ false) do
    classes = "noselect ui stackable doubling grid"

    if debug do
      classes <> " debug"
    else
      classes
    end
  end
end
