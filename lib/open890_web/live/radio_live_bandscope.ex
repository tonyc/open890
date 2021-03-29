defmodule Open890Web.Live.RadioLive.Bandscope do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast
  alias Open890.{ConnectionCommands, Extract, RadioConnection}
  alias Open890Web.Live.{BandButtonsComponent, Dispatch, RadioSocketState}

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

    config = "config/config.toml"
    |> File.read!()
    |> Toml.decode!()

    socket = socket |> assign(:__ui_macros, config["ui"]["macros"])

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

  # received by Task.async
  def handle_info({_ref, :ok}, socket) do
    {:noreply, socket}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle_band_selector", _params, socket) do
    new_state = !socket.assigns.display_band_selector

    socket = assign(socket, :display_band_selector, new_state)
    {:noreply, socket}
  end

  def handle_event("step_tune_up", %{"stepSize" => step_size} = _params, socket) do
    conn = socket.assigns.radio_connection

    conn |> ConnectionCommands.cmd("FC0#{step_size}")

    {:noreply, socket}
  end

  def handle_event("step_tune_down", %{"stepSize" => step_size} = _params, socket) do
    conn = socket.assigns.radio_connection

    conn |> ConnectionCommands.cmd("FC1#{step_size}")
    {:noreply, socket}
  end

  # close any open modals
  def handle_event("window_keyup", %{"key" => "Escape"} = _params, socket) do
    {:noreply, close_modals(socket)}
  end

  def handle_event("window_keyup", params, socket) do
    Logger.debug("window_keyup: #{inspect(params)}")

    {:noreply, socket}
  end

  def handle_event("dimmer_clicked", _params, socket) do
    {:noreply, close_modals(socket)}
  end

  def handle_event("run_macro", %{"name" => macro_name} = _params, socket) do
    commands = socket.assigns.__ui_macros
    |> Map.get(macro_name, %{})
    |> Map.get("commands", [])

    Logger.debug("Running macro: #{inspect(macro_name)}")

    case commands do
      [] ->
        :ok
      commands ->
        conn = socket.assigns.radio_connection

        Task.async(fn ->
          commands |> Enum.each(fn command ->
            Logger.debug("  Command: #{inspect(command)}")

            cond do
              command |> String.starts_with?("DE") ->
                delay_ms = Extract.delay_msec(command)
                Logger.debug("Processing special DELAY macro #{inspect(command)} for #{delay_ms} ms")
                Process.sleep(delay_ms)

              true ->
                conn |> ConnectionCommands.cmd(command)
                Process.sleep(50)
            end

          end)
        end)

      :ok

    end

    {:noreply, socket}
  end

  def handle_event(event, params, socket) do
    Logger.warn("RadioLive.Bandscope: Unknown event: #{event}, params: #{inspect(params)}")
    {:noreply, socket}
  end

  defp close_modals(socket) do
    socket |> assign(display_band_selector: false, display_screen_id: 0)
  end

end
