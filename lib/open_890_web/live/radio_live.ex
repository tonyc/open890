defmodule Open890Web.Live.RadioLive do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast
  alias Open890.TCPClient, as: Radio

  alias Open890Web.Live.Dispatch

  alias Open890Web.Live.{ButtonsComponent}

  @init_socket [
    {:debug, false},
    {:active_frequency, ""},
    {:active_mode, :unknown},
    {:active_receiver, :a},
    {:active_transmitter, :a},
    {:audio_scope_data, []},
    {:band_scope_att, nil},
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
    {:projected_active_receiver_location, ""},
    {:ref_level, 0},
    {:rf_pre, 0},
    {:rf_att, 0},
    {:s_meter, 0},
    {:ssb_data_filter_mode, nil},
    {:ssb_filter_mode, nil},
    {:theme, "kenwood"},
    {:vfo_a_frequency, ""},
    {:vfo_b_frequency, ""}
  ]

  @impl true
  def mount(params, _session, socket) do
    Logger.info("LiveView mount()")

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:state")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:audio_scope")
      Phoenix.PubSub.subscribe(Open890.PubSub, "radio:band_scope")
    end

    get_initial_radio_state()

    socket = init_socket(socket)

    socket =
      if params["debug"] do
        socket |> assign(:debug, true)
      else
        socket
      end

    socket =
      if params["wide"] do
        socket |> assign(:layout_wide, "")
      else
        socket |> assign(:layout_wide, "container")
      end

    {:ok, socket}
  end

  defp get_initial_radio_state do
    Radio.get_active_receiver()
    Radio.get_vfo_a_freq()
    Radio.get_vfo_b_freq()
    Radio.get_s_meter()
    Radio.get_modes()
    Radio.get_filter_modes()
    Radio.get_filter_state()
    Radio.get_band_scope_limits()
    Radio.get_band_scope_mode()
    Radio.get_band_scope_att()
    Radio.get_display_screen()
    Radio.get_rf_pre_att()
    Radio.get_ref_level()

    Radio.monitor_meters()
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
