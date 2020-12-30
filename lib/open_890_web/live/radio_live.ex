defmodule Open890Web.Live.RadioLive do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast
  alias Open890.TCPClient, as: Radio
  alias Open890.Extract

  alias Open890Web.RadioViewHelpers
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
    {:projected_active_receiver_location, ""},
    {:rf_pre, 0},
    {:rf_att, 0},
    {:s_meter, 0},
    {:ssb_data_filter_mode, nil},
    {:ssb_filter_mode, nil},
    {:theme, "kenwood"},
    {:vfo_a_frequency, ""},
    {:vfo_b_frequency, ""},
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

    socket = if params["debug"] do
      socket |> assign(:debug, true)
    else
      socket
    end

    socket = if params["wide"] do
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
  end

  defp init_socket(socket) do
    @init_socket
    |> Enum.reduce(socket, fn {key, val}, socket ->
      socket |> assign(key, val)
    end)
  end

  @impl true
  def handle_info(%Broadcast{event: "scope_data", payload: %{payload: audio_scope_data}}, socket) do
    {:noreply,
      socket
      |> push_event("scope_data", %{scope_data: audio_scope_data})
      |> assign(:audio_scope_data, audio_scope_data)}
  end

  @impl true
  def handle_info(%Broadcast{event: "band_scope_data", payload: %{payload: band_scope_data}}, socket) do
    {:noreply,
     socket
     |> push_event("band_scope_data", %{scope_data: band_scope_data})
     |> assign(:band_scope_data, band_scope_data)}
  end

  @impl true
  def handle_info(%Broadcast{event: "radio_state_data", payload: payload}, socket) do
    %{msg: msg} = payload

    socket = cond do
      msg |> String.starts_with?("RA") ->
        rf_att = msg |> Extract.rf_att()
        socket |> assign(:rf_att, rf_att)

      msg |> String.starts_with?("PA") ->
        socket |> assign(:rf_pre, Extract.rf_pre(msg))

      msg |> String.starts_with?("BS3") ->
        socket |> assign(:band_scope_mode, Extract.scope_mode(msg))

      msg |> String.starts_with?("BS8") ->
        socket |> assign(:band_scope_att, Extract.band_scope_att(msg))

      msg |> String.starts_with?("DS1") ->
        socket |> assign(:display_screen_id, Extract.display_screen_id(msg))

      msg |> String.starts_with?("OM0") ->
        socket |> assign(:active_mode, Extract.operating_mode(msg))

      msg |> String.starts_with?("OM1") ->
        socket |> assign(:inactive_mode, Extract.operating_mode(msg))

      msg |> String.starts_with?("SM") ->
        socket |> assign(:s_meter, Extract.s_meter(msg))

      msg |> String.starts_with?("FA") ->
        frequency = msg |> Extract.frequency()
        socket = socket |> assign(:vfo_a_frequency, frequency)

        socket =
          if socket.assigns[:active_receiver] == :a do
            socket
            |> assign(:page_title, frequency |> RadioViewHelpers.format_raw_frequency())
            |> assign(:active_frequency, frequency)
          else
            socket
            |> assign(:inactive_frequency, frequency)
          end

        socket |> vfo_a_updated()

      msg |> String.starts_with?("FB") ->
        frequency = msg |> Extract.frequency()
        socket = socket |> assign(:vfo_b_frequency, frequency)

        socket = if socket.assigns[:active_receiver] == :b do
          socket
          |> assign(:page_title, frequency |> RadioViewHelpers.format_raw_frequency())
          |> assign(:active_frequency, frequency)
        else
          socket
          |> assign(:inactive_frequency, frequency)
        end

        socket

      # high/shift
      msg |> String.starts_with?("SH0") ->
        %{
          active_mode: current_mode,
          ssb_filter_mode: filter_mode
        } = socket.assigns

        filter_hi_shift = msg
        |> Extract.passband_id()
        |> Extract.filter_hi_shift(filter_mode, current_mode)

        socket
        |> assign(:filter_hi_shift, filter_hi_shift)
        |> update_filter_hi_edge()

      # lo/width
      msg |> String.starts_with?("SL0") ->
        %{
          active_mode: current_mode,
          ssb_filter_mode: filter_mode
        } = socket.assigns

        filter_lo_width = msg
        |> Extract.passband_id()
        |> Extract.filter_lo_width(filter_mode, current_mode)

        socket
        |> assign(:filter_lo_width, filter_lo_width)
        |> update_filter_lo_edge()

      # ssb/ssb+data filter modes
      msg |> String.starts_with?("EX00611") ->
        socket
        |> assign(:ssb_filter_mode, Extract.filter_mode(msg))

      msg |> String.starts_with?("EX00612") ->
        socket
        |> assign(:ssb_data_filter_mode, Extract.filter_mode(msg))

      msg == "FR0" ->
        socket
        |> assign(:active_receiver, :a)
        |> assign(:active_frequency, socket.assigns.vfo_a_frequency)
        |> assign(:inactive_receiver, :b)
        |> assign(:inactive_frequency, socket.assigns.vfo_b_frequency)

      msg == "FR1" ->
        socket
        |> assign(:active_receiver, :b)
        |> assign(:active_frequency, socket.assigns.vfo_b_frequency)
        |> assign(:inactive_receiver, :a)
        |> assign(:inactive_frequency, socket.assigns.vfo_a_frequency)

      msg |> String.starts_with?("BSM0") ->
        [bs_low, bs_high] = msg |> Extract.band_edges()

        [low_int, high_int] =
          [bs_low, bs_high]
          |> Enum.map(&Kernel.div(&1, 1000))

        span =
          (high_int - low_int)
          |> to_string()
          |> String.trim_leading("0")
          |> String.to_integer()

         socket
         |> assign(:band_scope_edges, {bs_low, bs_high})
         |> assign(:band_scope_span, span)

      true ->
        Logger.debug("RadioLive: unknown message: #{inspect(msg)}")
        socket
    end

    {:noreply, socket}
  end

  def handle_info(%Broadcast{}, socket) do
    {:noreply, socket}
  end


  defp vfo_a_updated(socket) do
    socket
    |> update_filter_hi_edge()
    |> update_filter_lo_edge()
  end

  defp update_filter_edges(socket) do
    socket
    |> update_filter_hi_edge()
    |> update_filter_lo_edge()
  end

  defp update_filter_hi_edge(socket) do
    %{
      active_mode: active_mode,
      ssb_filter_mode: _ssb_filter_mode,
      ssb_data_filter_mode: _ssb_data_filter_mode,
      filter_hi_shift: filter_hi_shift
    } = socket.assigns

    active_frequency = socket |> get_active_receiver_frequency()

    case active_mode do
      mode when active_mode in [:lsb, :usb, :cw, :cw_r] ->
        socket
        |> assign(:filter_high_freq, offset_frequency(mode, active_frequency, filter_hi_shift))
      _ ->
        socket
    end
  end

  defp update_filter_lo_edge(socket) do
    %{
      active_mode: active_mode,
      ssb_filter_mode: _ssb_filter_mode,
      ssb_data_filter_mode: _ssb_data_filter_mode,
      filter_lo_width: filter_lo_width
    } = socket.assigns

    active_frequency = socket |> get_active_receiver_frequency()

    case active_mode do
      mode when active_mode in [:lsb, :usb, :cw, :cw_r] ->
        socket
        |> assign(:filter_low_freq, offset_frequency_reverse(mode, active_frequency, filter_lo_width))
      _ ->
        socket
    end
  end

  defp get_active_receiver_frequency(socket) do
    socket.assigns.active_receiver
    |> case do
      :a -> socket.assigns.vfo_a_frequency
      :b -> socket.assigns.vfo_b_frequency
    end
  end

end
