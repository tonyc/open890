defmodule Open890Web.Live.Dispatch do
  require Logger

  alias Open890.{AntennaState, Extract, TransverterState}
  alias Open890Web.RadioViewHelpers

  import Phoenix.LiveView, only: [assign: 3, push_event: 3]

  def dispatch("GC" <> _rest = msg, socket) do
    socket |> assign(:agc, Extract.agc(msg))
  end

  def dispatch("TX0", socket) do
    socket |> assign(:tx_state, :send)
  end

  def dispatch("TX1", socket) do
    socket |> assign(:tx_state, :data_send)
  end

  def dispatch("TX2", socket) do
    socket |> assign(:tx_state, :tx_tune)
  end

  def dispatch("RX" = _msg, socket) do
    socket |> assign(:tx_state, :off)
  end

  def dispatch("SD" <> _ = msg, socket) do
    cw_delay = Extract.cw_delay(msg)
    socket |> assign(:cw_delay, cw_delay)
  end

  def dispatch("KS" <> _ = msg, socket) do
    key_speed = Extract.key_speed(msg)
    socket |> assign(:cw_key_speed, key_speed)
  end

  def dispatch("AN" <> _rest = msg, socket) do
    %AntennaState{} = antenna_state = Extract.antenna_state(msg)

    socket |> assign(:antenna_state, antenna_state)
  end

  def dispatch("XV" <> _rest = msg, socket) do
    value = msg |> Extract.transverter_enabled()

    xv_state = socket.assigns[:transverter_state]
    |> case do
      %TransverterState{} = state ->
        %{state | enabled: value}
      _ ->
        %TransverterState{enabled: value}
    end

    socket |> assign(:transverter_state, xv_state)
  end

  def dispatch("XO" <> _rest = msg, socket) do
    value = msg |> Extract.transverter_offset()

    xv_state = socket.assigns[:transverter_state]
    |> case do
      %TransverterState{} = state ->
        %{state | offset: value}
      _ ->
        %TransverterState{offset: value}
    end

    socket |> assign(:transverter_state, xv_state)
  end

  def dispatch("MV" <> _rest = msg, socket) do
    value = msg |> Extract.vfo_memory_state()
    socket |> assign(:vfo_memory_state, value)
  end

  def dispatch("BP" <> _rest = msg, socket) do
    value = msg |> Extract.notch_filter()
    socket |> assign(:notch_filter, value)
  end

  def dispatch("NT" <> _rest = msg, socket) do
    value = msg |> Extract.notch_state()
    socket |> assign(:notch_state, value)
  end

  def dispatch("PC" <> _rest = msg, socket) do
    value = msg |> Extract.power_level()
    socket |> assign(:power_level, value)
  end

  def dispatch("RG" <> _rest = msg, socket) do
    rf_gain = msg |> Extract.rf_gain()
    socket |> assign(:rf_gain, rf_gain)
  end

  def dispatch("AG" <> _rest = msg, socket) do
    audio_gain = msg |> Extract.audio_gain()
    socket |> assign(:audio_gain, audio_gain)
  end

  def dispatch("DD0" <> _rest = msg, socket) do
    data_speed = msg |> Extract.data_speed()
    socket |> assign(:data_speed, data_speed)
  end

  def dispatch("BSA" <> _rest = msg, socket) do
    avg_level = msg |> Extract.band_scope_avg()
    socket |> assign(:band_scope_avg, avg_level)
  end

  def dispatch("BSC0" <> _rest = msg, socket) do
    ref_level = msg |> Extract.ref_level()
    socket |> assign(:ref_level, ref_level)
  end

  def dispatch("BSD" <> _rest, socket) do
    socket |> push_event("clear_band_scope", %{})
  end

  def dispatch("BSM0" <> _rest = msg, socket) do
    [bs_low, bs_high] = msg |> Extract.band_edges()

    [low_int, high_int] =
      [bs_low, bs_high]
      |> Enum.map(&Kernel.div(&1, 1000))

    span =
      (high_int - low_int)
      |> to_string()
      |> String.trim_leading("0")
      |> String.to_integer()

    case socket.assigns.band_scope_mode do
      :fixed ->
        socket
        |> assign(:band_scope_edges, {bs_low, bs_high})
        |> assign(:band_scope_fixed_span, span)

      :auto_scroll ->
        socket
        |> assign(:band_scope_edges, {bs_low, bs_high})

      :center ->
        socket

      _ ->
        socket
    end
  end

  # band_scope_mode
  def dispatch("BS3" <> _rest = msg, socket) do
    scope_mode = msg |> Extract.scope_mode()

    socket = socket |> assign(:band_scope_mode, scope_mode)

    if scope_mode == :center && !is_nil(socket.assigns.band_scope_span) do
      band_scope_edges =
        calculate_center_mode_edges(
          socket.assigns.active_frequency,
          socket.assigns.band_scope_span
        )

      socket |> assign(:band_scope_edges, band_scope_edges)
    else
      socket
    end
  end

  # band_scope_span
  def dispatch("BS4" <> _rest = msg, socket) do
    scope_span_khz = msg |> Extract.band_scope_span()

    socket = socket |> assign(:band_scope_span, scope_span_khz)

    case socket.assigns.band_scope_mode do
      mode when mode in [:center, :auto_scroll] ->
        band_scope_edges =
          calculate_center_mode_edges(
            socket.assigns.active_frequency,
            socket.assigns.band_scope_span
          )

        socket |> assign(:band_scope_edges, band_scope_edges)

      _ ->
        socket
    end
  end

  def dispatch("BS8" <> _rest = msg, socket) do
    socket |> assign(:band_scope_att, Extract.band_scope_att(msg))
  end

  def dispatch("DS1" <> _rest = msg, socket) do
    socket |> assign(:display_screen_id, Extract.display_screen_id(msg))
  end

  def dispatch("EX00611" <> _rest = msg, socket) do
    socket
    |> assign(:ssb_filter_mode, Extract.filter_mode(msg))
  end

  def dispatch("EX00612" <> _rest = msg, socket) do
    socket
    |> assign(:ssb_data_filter_mode, Extract.filter_mode(msg))
  end

  def dispatch("FA" <> _rest = msg, socket) do
    frequency = msg |> Extract.frequency()
    socket = socket |> assign(:vfo_a_frequency, frequency)
    previous_active_frequency = socket.assigns[:active_frequency] || 0
    delta = frequency - previous_active_frequency

    socket =
      if socket.assigns[:active_receiver] == :a do
        formatted_frequency = frequency |> RadioViewHelpers.format_raw_frequency()
        formatted_mode = socket.assigns[:active_mode] |> RadioViewHelpers.format_mode()
        page_title = "#{formatted_frequency} - #{formatted_mode}"

        socket
        |> assign(:page_title, page_title)
        |> assign(:active_frequency, frequency)
        |> assign(:active_frequency_delta, delta)
      else
        socket
        |> assign(:inactive_frequency, frequency)
      end

    socket =
      if socket.assigns[:band_scope_mode] == :center && socket.assigns.active_receiver == :a do
        band_scope_edges =
          calculate_center_mode_edges(
            socket.assigns.active_frequency,
            socket.assigns.band_scope_span
          )

        {low, high} = band_scope_edges

        socket
        |> assign(:band_scope_edges, band_scope_edges)
        |> push_event("freq_delta", %{delta: delta, vfo: "a", bs: %{low: low, high: high}})
      else
        socket
      end

    socket |> vfo_a_updated()
  end

  def dispatch("FB" <> _rest = msg, socket) do
    frequency = msg |> Extract.frequency()
    socket = socket |> assign(:vfo_b_frequency, frequency)

    previous_active_frequency = socket.assigns[:active_frequency] || 0
    delta = frequency - previous_active_frequency

    socket =
      if socket.assigns[:active_receiver] == :b do
        formatted_frequency = frequency |> RadioViewHelpers.format_raw_frequency()
        formatted_mode = socket.assigns[:active_mode] |> RadioViewHelpers.format_mode()
        page_title = "#{formatted_frequency} - #{formatted_mode}"

        socket
        |> assign(:page_title, page_title)
        |> assign(:active_frequency, frequency)
        |> assign(:active_frequency_delta, delta)
      else
        socket
        |> assign(:inactive_frequency, frequency)
      end

    socket =
      if socket.assigns[:band_scope_mode] == :center && socket.assigns.active_receiver == :b do
        band_scope_edges =
          calculate_center_mode_edges(
            socket.assigns.active_frequency,
            socket.assigns.band_scope_span
          )

        {low, high} = band_scope_edges

        socket
        |> assign(:band_scope_edges, band_scope_edges)
        |> push_event("freq_delta", %{delta: delta, vfo: "b", bs: %{low: low, high: high}})

      else
        socket
      end

    socket
  end

  def dispatch("FL0" <> _rest = msg, socket) do
    if_filter = msg |> Extract.current_if_filter()
    socket |> assign(:active_if_filter, if_filter)
  end

  def dispatch("FL1" <> _rest = msg, socket) do
    {filter_id, filter_value} = msg |> Extract.roofing_filter()

    roofing_filter_data =
      socket.assigns.roofing_filter_data
      |> Map.put(filter_id, filter_value)

    socket |> assign(:roofing_filter_data, roofing_filter_data)
  end

  def dispatch("FR0", socket) do
    socket
    |> assign(:active_receiver, :a)
    |> assign(:active_frequency, socket.assigns.vfo_a_frequency)
    |> assign(:inactive_receiver, :b)
    |> assign(:inactive_frequency, socket.assigns.vfo_b_frequency)
  end

  def dispatch("FR1", socket) do
    socket
    |> assign(:active_receiver, :b)
    |> assign(:active_frequency, socket.assigns.vfo_b_frequency)
    |> assign(:inactive_receiver, :a)
    |> assign(:inactive_frequency, socket.assigns.vfo_a_frequency)
  end

  def dispatch("OM0" <> _rest = msg, socket) do
    frequency = socket.assigns[:active_frequency]

    mode = msg |> Extract.operating_mode()

    formatted_frequency = frequency |> RadioViewHelpers.format_raw_frequency()
    formatted_mode = mode |> RadioViewHelpers.format_mode()
    page_title = "#{formatted_frequency} - #{formatted_mode}"

    socket
    |> assign(:active_mode, mode)
    |> assign(:page_title, page_title)
  end

  def dispatch("OM1" <> _rest = msg, socket) do
    socket |> assign(:inactive_mode, Extract.operating_mode(msg))
  end

  def dispatch("PA" <> _rest = msg, socket) do
    socket |> assign(:rf_pre, Extract.rf_pre(msg))
  end

  def dispatch("RA" <> _rest = msg, socket) do
    rf_att = msg |> Extract.rf_att()
    socket |> assign(:rf_att, rf_att)
  end

  def dispatch("RM1" <> _rest = msg, socket) do
    meter = msg |> Extract.alc_meter()
    socket |> assign(:alc_meter, meter)
  end

  def dispatch("RM2" <> _rest = msg, socket) do
    meter = msg |> Extract.swr_meter()
    socket |> assign(:swr_meter, meter)
  end

  def dispatch("RM3" <> _rest = msg, socket) do
    meter = msg |> Extract.comp_meter()
    socket |> assign(:comp_meter, meter)
  end

  def dispatch("RM4" <> _rest = msg, socket) do
    meter = msg |> Extract.id_meter()
    socket |> assign(:id_meter, meter)
  end

  def dispatch("RM5" <> _rest = msg, socket) do
    meter = msg |> Extract.vd_meter()
    socket |> assign(:vd_meter, meter)
  end

  def dispatch("RM6" <> _rest = msg, socket) do
    meter = msg |> Extract.temp_meter()
    socket |> assign(:temp_meter, meter)
  end

  def dispatch("SH0" <> _rest = msg, socket) do
    %{
      active_mode: current_mode,
      ssb_filter_mode: filter_mode
    } = socket.assigns

    filter_hi_shift =
      msg
      |> Extract.passband_id()
      |> Extract.filter_hi_shift(filter_mode, current_mode)

    socket
    |> assign(:filter_hi_shift, filter_hi_shift)
    |> update_filter_hi_edge()
  end

  def dispatch("SL0" <> _rest = msg, socket) do
    %{
      active_mode: current_mode,
      ssb_filter_mode: filter_mode
    } = socket.assigns

    filter_lo_width =
      msg
      |> Extract.passband_id()
      |> Extract.filter_lo_width(filter_mode, current_mode)

    socket
    |> assign(:filter_lo_width, filter_lo_width)
    |> update_filter_lo_edge()
  end

  def dispatch("SM" <> _rest = msg, socket) do
    socket |> assign(:s_meter, Extract.s_meter(msg))
  end

  ## dispatch catchall - this needs to be the very last one
  def dispatch(msg, socket) do
    Logger.debug("Dispatch: unknown message: #{inspect(msg)}")

    socket
  end

  ### END dispatching

  ### everything under here is used by the dispatch functions
  defp vfo_a_updated(socket) do
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
        |> assign(
          :filter_high_freq,
          RadioViewHelpers.offset_frequency(mode, active_frequency, filter_hi_shift)
        )

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
        |> assign(
          :filter_low_freq,
          RadioViewHelpers.offset_frequency_reverse(mode, active_frequency, filter_lo_width)
        )

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

  defp calculate_center_mode_edges(freq, span_khz)
       when is_integer(freq) and is_integer(span_khz) do
    span = span_khz * 1000
    half_span = span |> div(2)

    bs_low = freq - half_span
    bs_high = freq + half_span

    {bs_low, bs_high}
  end
end
