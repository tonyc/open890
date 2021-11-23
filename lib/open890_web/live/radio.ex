defmodule Open890Web.Live.Radio do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast
  alias Open890.{ConnectionCommands, Extract, RadioConnection}
  alias Open890Web.Live.{BandButtonsComponent, Dispatch, RadioSocketState}

  alias Open890Web.Components.{AudioScope, BandScope, Slider}

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

  # Connection state messages
  def handle_info(%Broadcast{event: "connection_state", payload: payload}, socket) do
    Logger.debug("Bandscope LV: RX connection_state: #{inspect(payload)}")

    {:noreply, assign(socket, :connection_state, payload)}
  end

  # def handle_info(%Broadcast{event: "radio_info", payload: %{level: level, msg: msg}}, socket) do
  #   Logger.info("***** radio_info: [#{level}] msg: #{inspect(msg)}")
  #   {:noreply, put_flash(socket, level, msg)}
  # end

  def handle_info(%Broadcast{} = bc, socket) do
    Logger.warn("Unknown broadcast: #{inspect(bc)}")

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


  def handle_event("window_keydown", %{"key" => key} = params, socket) do
    Logger.debug("window_keydown: #{inspect(params)}")

    conn = socket.assigns.radio_connection

    case key do
      "]" ->
        conn |> ConnectionCommands.freq_change(:up)

      "[" ->
        conn |> ConnectionCommands.freq_change(:down)

      _ -> :ok

    end

    {:noreply, socket}
  end

  def handle_event("window_keydown", params, socket) do
    Logger.debug("window_keydown: #{inspect(params)}")

    {:noreply, socket}
  end

  # close any open modals
  def handle_event("window_keyup", %{"key" => "Escape"} = _params, socket) do
    {:noreply, close_modals(socket)}
  end

  def handle_event("window_keyup", %{"key" => key} = params, socket) do
    Logger.debug("window_keyup: #{inspect(params)}")

    conn = socket.assigns.radio_connection

    case key do
      "s" ->
        conn |> ConnectionCommands.band_scope_shift()

      _ -> :ok
    end

    {:noreply, socket}
  end

  def handle_event("window_keyup", params, socket) do
    Logger.debug("window_keyup: #{inspect(params)}")

    {:noreply, socket}
  end

  def handle_event("start_connection", _params, socket) do
    RadioConnection.start(socket.assigns.radio_connection.id)

    {:noreply, socket}
  end

  def handle_event("stop_connection", _params, socket) do
    RadioConnection.stop(socket.assigns.radio_connection.id)

    {:noreply, socket}
  end

  def handle_event("dimmer_clicked", _params, socket) do
    {:noreply, close_modals(socket)}
  end

  def handle_event("run_macro", %{"name" => macro_name} = _params, socket) do
    Logger.debug("Running macro: #{inspect(macro_name)}")

    commands =
      socket.assigns.__ui_macros
      |> Enum.find(fn x -> x["label"] == macro_name end)
      |> case do
        %{"commands" => commands} ->
          commands

        _ ->
          []
      end

    case commands do
      [] ->
        :ok

      commands ->
        conn = socket.assigns.radio_connection

        Task.async(fn ->
          commands
          |> Enum.each(fn command ->
            Logger.debug("  Command: #{inspect(command)}")

            cond do
              command |> String.starts_with?("DE") ->
                delay_ms = Extract.delay_msec(command)

                Logger.debug(
                  "Processing special DELAY macro #{inspect(command)} for #{delay_ms} ms"
                )

                Process.sleep(delay_ms)

              true ->
                conn |> ConnectionCommands.cmd(command)
                Process.sleep(100)
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

  def radio_classes(debug \\ false) do
    classes = "noselect ui stackable doubling grid"

    if debug do
      classes <> " debug"
    else
      classes
    end
  end
end
