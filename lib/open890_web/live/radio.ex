defmodule Open890Web.Live.Radio do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast

  alias Open890.{
    ConnectionCommands,
    Extract,
    KeyboardEntryState,
    RadioConnection,
    RadioState,
    UserMarker
  }

  alias Open890Web.Live.{BandButtonsComponent, RadioSocketState}

  alias Open890Web.Components.{
    AtuIndicator,
    AudioScope,
    BandScope,
    BusyTxIndicator,
    FineButton,
    LockButton,
    Meter,
    MhzButton,
    RitXit,
    Slider,
    SplitButton
  }

  import Open890Web.Components.Buttons

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
          Logger.info(
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
          socket |> redirect(to: "/connections")
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    selected_tab = params["panelTab"]

    panel_open = params |> Map.get("panel", "true") == "true"

    socket =
      socket
      |> assign(active_tab: selected_tab)
      |> assign(left_panel_open: panel_open)

    {:noreply, socket}
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
  def handle_info(%Broadcast{event: "lock_state", payload: locked}, socket) do
    {:noreply, socket |> push_event("lock_state", %{locked: locked})}
  end

  @impl true
  def handle_info(%Broadcast{event: "band_scope_cleared"}, socket) do
    {:noreply, socket |> push_event("clear_band_scope", %{})}
  end

  @impl true
  def handle_info(%Broadcast{event: "radio_state_data", payload: %{msg: radio_state}}, socket) do
    formatted_frequency =
      radio_state
      |> RadioState.effective_active_frequency()
      |> RadioViewHelpers.format_raw_frequency()

    formatted_mode =
      radio_state
      |> RadioState.effective_active_mode()
      |> RadioViewHelpers.format_mode()

    page_title = "#{formatted_frequency} - #{formatted_mode}"

    socket =
      assign(socket, :radio_state, radio_state)
      |> assign(:page_title, page_title)

    {:noreply, socket}
  end

  # Connection state messages
  def handle_info(%Broadcast{event: "connection_state", payload: payload}, socket) do
    Logger.debug("Bandscope LV: RX connection_state: #{inspect(payload)}")

    {:noreply, assign(socket, :connection_state, payload)}
  end

  def handle_info(%Broadcast{event: "freq_delta", payload: payload}, socket) do
    socket =
      if socket.assigns.radio_state.band_scope_mode == :center do
        socket |> push_event("freq_delta", payload)
      else
        socket
      end

    {:noreply, socket}
  end

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

  def handle_info(:expire_keyboard_state, socket) do
    Logger.info(":expire_keyboard_state")

    case socket.assigns.keyboard_entry_timer do
      nil ->
        Logger.info("expire_keyboard_state: wanted to cancel a nil timer")

      timer ->
        Logger.info("expire_keyboard_state: canceling timer")
        Process.cancel_timer(timer)

        Logger.info("expire_keyboard_state: transition to KeyboardEntryState.Normal")
    end

    # Always transition to normal
    socket =
      socket
      |> assign(keyboard_entry_state: KeyboardEntryState.Normal)
      |> assign(keyboard_entry_timer: nil)

    {:noreply, socket}
  end

  def handle_event("toggle_panel", _params, socket) do
    new_state = !socket.assigns.left_panel_open

    radio_conn = socket.assigns.radio_connection

    new_params = %{
      panel: new_state,
      panelTab: socket.assigns.active_tab
    }

    socket =
      socket
      |> push_patch(to: Routes.radio_path(socket, :show, radio_conn.id, new_params))

    {:noreply, socket}
  end

  def handle_event("toggle_band_selector", _params, socket) do
    new_state = !socket.assigns.display_band_selector
    socket = assign(socket, :display_band_selector, new_state)
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab_name}, socket) do
    Logger.info("set_tab: #{inspect(tab_name)}")

    radio_conn = socket.assigns.radio_connection

    new_params = %{
      panel: socket.assigns.left_panel_open,
      panelTab: tab_name
    }

    socket =
      socket
      |> push_patch(to: Routes.radio_path(socket, :show, radio_conn.id, new_params))

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
    Logger.debug("live/radio.ex: window_keydown: #{inspect(params)}")

    conn = socket.assigns.radio_connection

    case key do
      "]" ->
        conn |> ConnectionCommands.freq_change(:up)

      "[" ->
        conn |> ConnectionCommands.freq_change(:down)

      _ ->
        :ok
    end

    {:noreply, socket}
  end

  def handle_event("window_keydown", params, socket) do
    Logger.debug("live/radio.ex: window_keydown: #{inspect(params)}")

    {:noreply, socket}
  end

  # close any open modals
  def handle_event("window_keyup", %{"key" => "Escape"} = _params, socket) do
    {:noreply, close_modals(socket)}
  end

  def handle_event("window_keyup", %{"key" => key} = params, socket) do
    Logger.debug("live/radio.ex: window_keyup: #{inspect(params)}")
    Logger.info("KeyboardEntryState: #{socket.assigns.keyboard_entry_state}")

    socket = handle_keyboard_state(socket.assigns.keyboard_entry_state, key, socket)

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

  def handle_event("adjust_filter", params, socket) do
    Logger.info("adjust_filter: #{inspect(params)}")

    filter_state = socket.assigns.radio_state.filter_state
    connection = socket.assigns.radio_connection

    lo_width_passband_id = filter_state.lo_passband_id
    hi_shift_passband_id = filter_state.hi_passband_id

    is_up = params["dir"] == "up"

    if params["shift"] do
      # adjust shift
      new_passband_id =
        if is_up do
          hi_shift_passband_id + 1
        else
          hi_shift_passband_id - 1
        end
        |> to_string()
        |> String.pad_leading(4, "0")

      connection |> RadioConnection.cmd("SH#{new_passband_id}")
    else
      # width
      new_passband_id =
        if is_up do
          lo_width_passband_id + 1
        else
          lo_width_passband_id - 1
        end
        |> to_string()
        |> String.pad_leading(3, "0")

      connection |> RadioConnection.cmd("SL#{new_passband_id}")
    end

    {:noreply, socket}
  end

  def handle_event("delete_user_marker", %{"id" => marker_id} = _params, socket) do
    Logger.info("delete_user_marker, id: #{inspect(marker_id)}")

    conn = socket.assigns.radio_connection
    RadioConnection.delete_user_marker(conn, marker_id)

    # This block of code should go into RadioConnection.delete_user_marker(),
    # It should return the list of remaining markers for the socket.
    updated_markers =
      socket.assigns.markers
      |> Enum.reject(fn %UserMarker{id: id} ->
        id == marker_id
      end)

    socket = assign(socket, :markers, updated_markers)

    {:noreply, socket}
  end

  def handle_event("power_level_changed", %{"value" => power_level} = _params, socket) do
    Logger.info("power_level_changed: #{inspect power_level}")

    power_level = (power_level / 255.0) * 100 |> round()

    socket.assigns.radio_connection
    |> ConnectionCommands.set_power_level(power_level)

    {:noreply, socket}
  end

  def handle_event(event, params, socket) do
    Logger.warn("Live.Radio: Unknown event: #{event}, params: #{inspect(params)}")
    {:noreply, socket}
  end

  defp close_modals(socket) do
    socket |> assign(display_band_selector: false, display_screen_id: 0)
  end

  def radio_classes(debug \\ false) do
    classes = "ui grid noselect"

    if debug do
      classes <> " debug"
    else
      classes
    end
  end

  def panel_classes(flag) do
    if flag do
      "bandscopePanel left"
    else
      "bandscopePanel left hidden"
    end
  end

  def tab_classes(name, var) do
    if name == var do
      "item active"
    else
      "item"
    end
  end

  def tab_panel_classes(name, var) do
    if name == var do
      "ui tabs"
    else
      "ui tabs hidden"
    end
  end

  defp handle_keyboard_state(KeyboardEntryState.Normal, key, socket) do
    radio_state = socket.assigns.radio_state
    conn = socket.assigns.radio_connection

    case key do
      "s" ->
        conn |> ConnectionCommands.toggle_split(radio_state)
        socket

      "m" ->
        Logger.info("transition keyboard state to PlaceMarker")
        timer = Process.send_after(self(), :expire_keyboard_state, 2000)

        socket
        |> assign(:keyboard_entry_state, KeyboardEntryState.PlaceMarker)
        |> assign(:keyboard_entry_timer, timer)

      "h" ->
        conn |> ConnectionCommands.band_scope_shift()
        socket

      "c" ->
        Logger.info("transition keyboard state to ClearMarkers")
        timer = Process.send_after(self(), :expire_keyboard_state, 2000)

        socket
        |> assign(:keyboard_entry_state, KeyboardEntryState.ClearMarkers)
        |> assign(:keyboard_entry_timer, timer)

      "t" ->
        conn |> ConnectionCommands.cw_tune()
        socket

      "=" ->
        conn |> ConnectionCommands.equalize_vfo()
        socket

      "\\" ->
        conn |> ConnectionCommands.toggle_vfo(radio_state)
        socket

      _ ->
        socket
    end
  end

  defp handle_keyboard_state(KeyboardEntryState.PlaceMarker, key, socket) do
    radio_state = socket.assigns.radio_state

    case key do
      marker_key when marker_key in ["r", "g", "b", "m"] ->
        freq = RadioState.effective_active_frequency(radio_state)

        marker = UserMarker.create(freq)

        marker =
          case marker_key do
            "r" -> UserMarker.red(marker)
            "g" -> UserMarker.green(marker)
            "b" -> UserMarker.blue(marker)
            "m" -> UserMarker.white(marker)
          end

        socket = assign(socket, :markers, socket.assigns.markers ++ [marker])
        RadioConnection.add_user_marker(socket.assigns.radio_connection, marker)
        Logger.debug("Place marker: #{inspect(marker)}")

        if !is_nil(socket.assigns.keyboard_entry_timer) do
          Process.cancel_timer(socket.assigns.keyboard_entry_timer)
        end

        Logger.info("Transitioning to KeyboardEntryState.Normal")

        socket
        |> assign(:keyboard_entry_state, KeyboardEntryState.Normal)
        |> assign(:keyboard_entry_timer, nil)

      _ ->
        socket
    end
  end

  defp handle_keyboard_state(KeyboardEntryState.ClearMarkers, key, socket) do
    key_to_colors = %{
      "r" => :red,
      "g" => :green,
      "b" => :blue,
      "m" => :white
    }

    socket =
      case key do
        marker_key when marker_key in ["r", "g", "b", "c", "m"] ->
          existing_markers = socket.assigns.markers

          new_markers =
            Enum.reject(existing_markers, fn %UserMarker{color: color} ->
              if marker_key == "c" do
                true
              else
                color == key_to_colors[marker_key]
              end
            end)

          Logger.info("New markers: #{inspect(new_markers)}")

          assign(socket, :markers, new_markers)

        _ ->
          socket
      end

    Logger.info("Clear markers: canceling timer")

    if !is_nil(socket.assigns.keyboard_entry_timer) do
      Process.cancel_timer(socket.assigns.keyboard_entry_timer)
    end

    Logger.info("Clear markers: transitioning to KeyboardEntryState.Normal")

    socket
    |> assign(:keyboard_entry_state, KeyboardEntryState.Normal)
    |> assign(:keyboard_entry_timer, nil)
  end
end
