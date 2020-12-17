defmodule Open890Web.Live.RadioLive do
  require Logger

  use Open890Web, :live_view
  use Open890Web.Live.RadioLiveEventHandling

  alias Phoenix.Socket.Broadcast
  alias Open890.TCPClient, as: Radio
  alias Open890.Extract

  alias Open890Web.RadioViewHelpers

  @init_socket [
    {:debug, false},
    {:active_frequency, ""},
    {:active_mode, :unknown},
    {:active_receiver, :a},
    {:active_transmitter, :a},
    {:audio_scope_data, []},
    {:band_scope_data, []},
    {:band_scope_edges, nil},
    {:band_scope_mode, nil},
    {:band_scope_span, nil},
    {:filter_hi_shift, nil},
    {:filter_high_freq, nil},
    {:filter_lo_width, nil},
    {:filter_low_freq, nil},
    {:inactive_frequency, ""},
    {:inactive_mode, :unknown},
    {:inactive_receiver, :b},
    {:projected_active_receiver_location, ""},
    {:s_meter, 0},
    {:ssb_data_filter_mode, nil},
    {:ssb_filter_mode, nil},
    {:theme, "elecraft"},
    {:vfo_a_frequency, ""},
    {:vfo_b_frequency, ""},
  ]

  @impl true
  def mount(params, _session, socket) do
    Logger.info("LiveView mount()")

    params
    |> IO.inspect(label: "params", pretty: true, limit: :infinity)

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
  end

  defp init_socket(socket) do
    @init_socket
    |> Enum.reduce(socket, fn {key, val}, socket ->
      socket |> assign(key, val)
    end)
  end

  @impl true
  def handle_info(%Broadcast{event: "scope_data", payload: %{payload: audio_scope_data}}, socket) do
    {:noreply, socket |> assign(:audio_scope_data, audio_scope_data)}
  end

  @impl true
  def handle_info(%Broadcast{event: "band_scope_data", payload: %{payload: band_data}}, socket) do
    {:noreply,
     socket
     |> assign(:band_scope_data, band_data)}
  end

  @impl true
  def handle_info(%Broadcast{event: "radio_state_data", payload: payload}, socket) do
    %{msg: msg} = payload

    cond do
      msg |> String.starts_with?("OM0") ->
        mode = msg |> Extract.operating_mode()

        socket = socket |> assign(:active_mode, mode)

        {:noreply, socket}

      msg |> String.starts_with?("OM1") ->
        mode = msg |> Extract.operating_mode()

        socket = socket |> assign(:inactive_mode, mode)

        {:noreply, socket}

      msg |> String.starts_with?("SM") ->
        s_meter_value = msg |> Extract.s_meter()

        socket = socket |> assign(:s_meter, s_meter_value)

        {:noreply, socket}

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

        socket = socket |> vfo_a_updated()

        {:noreply, socket}

      msg |> String.starts_with?("FB") ->
        frequency = msg |> Extract.frequency()
        socket = socket |> assign(:vfo_b_frequency, frequency)

        socket =
          if socket.assigns[:active_receiver] == :b do
            socket
            |> assign(:page_title, frequency |> RadioViewHelpers.format_raw_frequency())
            |> assign(:active_frequency, frequency)
          else
            socket
            |> assign(:inactive_frequency, frequency)
          end

        {:noreply, socket}

      # high/shift
      msg |> String.starts_with?("SH0") ->
        %{
          active_mode: current_mode,
          ssb_filter_mode: filter_mode
        } = socket.assigns

        filter_hi_shift = msg
        |> Extract.passband_id()
        |> Extract.filter_hi_shift(filter_mode, current_mode)

        socket =
          socket
          |> assign(:filter_hi_shift, filter_hi_shift)
          |> update_filter_hi_edge()

        {:noreply, socket}

      # lo/width
      msg |> String.starts_with?("SL0") ->
        %{
          active_mode: current_mode,
          ssb_filter_mode: filter_mode
        } = socket.assigns

        filter_lo_width = msg
        |> Extract.passband_id()
        |> Extract.filter_lo_width(filter_mode, current_mode)

        socket =
          socket
          |> assign(:filter_lo_width, filter_lo_width)
          |> update_filter_lo_edge()

        {:noreply, socket}

      # ssb/ssb+data filter modes
      msg |> String.starts_with?("EX00611") ->
        ssb_filter_mode = msg |> Extract.filter_mode()
        {:noreply, socket |> assign(:ssb_filter_mode, ssb_filter_mode)}

      msg |> String.starts_with?("EX00612") ->
        ssb_data_filter_mode = msg |> Extract.filter_mode()
        {:noreply, socket |> assign(:ssb_data_filter_mode, ssb_data_filter_mode)}

      msg == "FR0" ->
        socket =
          socket
          |> assign(:active_receiver, :a)
          |> assign(:active_frequency, socket.assigns.vfo_a_frequency)
          |> assign(:inactive_receiver, :b)
          |> assign(:inactive_frequency, socket.assigns.vfo_b_frequency)

        {:noreply, socket}

      msg == "FR1" ->
        socket =
          socket
          |> assign(:active_receiver, :b)
          |> assign(:active_frequency, socket.assigns.vfo_b_frequency)
          |> assign(:inactive_receiver, :a)
          |> assign(:inactive_frequency, socket.assigns.vfo_a_frequency)

        {:noreply, socket}

      msg |> String.starts_with?("BSM0") ->
        [bs_low, bs_high] = msg |> Extract.band_edges()

        [low_int, high_int] =
          [bs_low, bs_high]
          |> Enum.map(&Kernel.div(&1, 1000))

        span =
          (high_int - low_int)
          |> to_string()
          |> String.trim_leading("0")

        {:noreply,
         socket
         |> assign(:band_scope_edges, {bs_low, bs_high})
         |> assign(:band_scope_span, span)}

      msg |> String.starts_with?("BS3") ->
        band_scope_mode = msg |> Extract.scope_mode()

        {:noreply, socket |> assign(:band_scope_mode, band_scope_mode)}
      true ->
        Logger.debug("RadioLive: unknown message: #{inspect(msg)}")
        {:noreply, socket}
    end
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
