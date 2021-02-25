defmodule Open890Web.Live.RadioLive.Bandscope do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast
  alias Open890.RadioConnection
  alias Open890.ConnectionCommands
  alias Open890Web.Live.Dispatch

  @init_socket [
    {:radio_connection, nil},
    {:connection_state, nil},
    {:data_speed, nil},
    {:debug, false},
    {:active_frequency, ""},
    {:active_mode, :unknown},
    {:active_receiver, :a},
    {:active_transmitter, :a},
    {:audio_gain, nil},
    {:audio_scope_data, []},
    {:band_scope_att, nil},
    {:band_scope_avg, nil},
    {:band_scope_data, []},
    {:band_scope_edges, nil},
    {:band_scope_mode, nil},
    {:band_scope_span, nil},
    {:display_screen_id, 0},
    {:filter_hi_shift, nil},
    {:filter_high_freq, nil},
    {:filter_lo_width, nil},
    {:filter_low_freq, nil},
    {:inactive_frequency, ""},
    {:inactive_mode, :unknown},
    {:inactive_receiver, :b},
    {:alc_meter, 0},
    {:swr_meter, 0},
    {:comp_meter, 0},
    {:id_meter, 0},
    {:vd_meter, 0},
    {:temp_meter, 0},
    {:power_level, nil},
    {:projected_active_receiver_location, ""},
    {:ref_level, 0},
    {:rf_gain, nil},
    {:rf_pre, 0},
    {:rf_att, 0},
    {:active_if_filter, nil},
    {:roofing_filter_data, %{a: nil, b: nil, c: nil}},
    {:s_meter, 0},
    {:ssb_data_filter_mode, nil},
    {:ssb_filter_mode, nil},
    {:theme, "kenwood"},
    {:vfo_a_frequency, ""},
    {:vfo_b_frequency, ""}
  ]

  @impl true
  def render(assigns) do
    Phoenix.View.render(Open890Web.RadioLiveView, "radio_live.html", assigns)
  end

  @impl true
  def mount(%{"id" => connection_id} = params, _session, socket) do
    Logger.info("LiveView mount: params: #{inspect(params)}")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:state")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:audio_scope")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:band_scope")
    end

    socket = init_socket(socket)

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

  defp init_socket(socket) do
    initial_state = @init_socket |> Enum.into(%{})

    socket |> assign(initial_state)
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
end
