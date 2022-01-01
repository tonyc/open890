defmodule Open890Web.Live.Dispatch do
  require Logger

  alias Open890.{AntennaState, Extract, NoiseBlankState, NotchState, TransverterState}
  alias Open890Web.RadioViewHelpers
  alias Open890.RadioState

  import Phoenix.LiveView, only: [assign: 3, push_event: 3]

  def dispatch("##VP1" <> _rest = msg, socket) do
    socket |> put_radio_state(:voip_enabled, true)
  end

  def dispatch("##VP0" <> _rest = msg, socket) do
    socket |> put_radio_state(:voip_enabled, false)
  end

  def dispatch("##KN21" <> _rest = msg, socket) do
    socket |> put_radio_state(:voip_available, true)
  end

  def dispatch("##KN20" <> _rest = msg, socket) do
    socket |> put_radio_state(:voip_available, false)
  end

  def dispatch("AP0" <> _rest = msg, socket) do
    socket |> put_radio_state(:apf_enabled, Extract.apf_enabled(msg))
  end

  def dispatch("TB" <> _rest = msg, socket) do
    socket |> put_radio_state(:split_enabled, Extract.split_enabled(msg))
  end

  def dispatch("SQ" <> _rest = msg, socket) do
    socket |> put_radio_state(:squelch, Extract.sql(msg))
  end

  def dispatch("GC" <> _rest = msg, socket) do
    socket |> put_radio_state(:agc, Extract.agc(msg))
  end

  def dispatch("NR" <> _rest = msg, socket) do
    socket |> put_radio_state(:nr, Extract.nr(msg))
  end

  def dispatch("BC" <> _rest = msg, socket) do
    socket |> put_radio_state(:bc, Extract.bc(msg))
  end

  def dispatch("MG" <> _rest = msg, socket) do
    socket |> put_radio_state(:mic_gain, Extract.mic_gain(msg))
  end

  def dispatch("TX0", socket) do
    socket |> put_radio_state(:tx_state, :send)
  end

  def dispatch("TX1", socket) do
    socket |> put_radio_state(:tx_state, :data_send)
  end

  def dispatch("TX2", socket) do
    socket |> put_radio_state(:tx_state, :tx_tune)
  end

  def dispatch("RX" = _msg, socket) do
    socket |> put_radio_state(:tx_state, :off)
  end

  def dispatch("SD" <> _ = msg, socket) do
    cw_delay = Extract.cw_delay(msg)
    socket |> put_radio_state(:cw_delay, cw_delay)
  end

  def dispatch("KS" <> _ = msg, socket) do
    key_speed = Extract.key_speed(msg)
    socket |> put_radio_state(:cw_key_speed, key_speed)
  end

  def dispatch("AN" <> _rest = msg, socket) do
    %AntennaState{} = antenna_state = Extract.antenna_state(msg)

    socket |> put_radio_state(:antenna_state, antenna_state)
  end

  def dispatch("XV" <> _rest = msg, socket) do
    value = msg |> Extract.transverter_enabled()

    xv_state = socket.assigns[:radio_state].transverter_state
    |> case do
      %TransverterState{} = state ->
        %{state | enabled: value}
      _ ->
        %TransverterState{enabled: value}
    end

    socket |> put_radio_state(:transverter_state, xv_state)
  end

  def dispatch("XO" <> _rest = msg, socket) do
    value = msg |> Extract.transverter_offset()

    xv_state = socket.assigns[:radio_state].transverter_state
    |> case do
      %TransverterState{} = state ->
        %{state | offset: value}
      _ ->
        %TransverterState{offset: value}
    end

    socket |> put_radio_state(:transverter_state, xv_state)
  end

  def dispatch("MV" <> _rest = msg, socket) do
    value = msg |> Extract.vfo_memory_state()
    socket |> put_radio_state(:vfo_memory_state, value)
  end

  def dispatch("NB1" <> _rest = msg, socket) do
    enabled = msg |> Extract.nb_enabled()

    nb_state = socket.assigns[:radio_state].noise_blank_state
    |> case do
      %NoiseBlankState{} = state ->
        %{state | nb_1_enabled: enabled}

      _ -> %NoiseBlankState{nb_1_enabled: enabled}
    end

    socket |> put_radio_state(:noise_blank_state, nb_state)
  end

  def dispatch("NB2" <> _rest = msg, socket) do
    enabled = msg |> Extract.nb_enabled()

    nb_state = socket.assigns[:radio_state].noise_blank_state
    |> case do
      %NoiseBlankState{} = state ->
        %{state | nb_2_enabled: enabled}

      _ -> %NoiseBlankState{nb_2_enabled: enabled}
    end

    socket |> put_radio_state(:noise_blank_state, nb_state)
  end


  # Notch on/off
  def dispatch("NT" <> _rest = msg, socket) do
    notch_enabled = msg |> Extract.notch_state()

    notch_state = socket.assigns[:radio_state].notch_state
    |> case do
      %NotchState{} = state ->
        %{state | enabled: notch_enabled}

      _ ->
        %NotchState{enabled: notch_enabled}
    end

    socket |> put_radio_state(:notch_state, notch_state)
  end

  # notch frequency
  def dispatch("BP" <> _rest = msg, socket) do
    notch_frequency = Extract.notch_filter(msg)

    notch_state = socket.assigns[:radio_state].notch_state
    |> case do
      %NotchState{} = state ->
        %{state | frequency: notch_frequency}
      _ ->
        %NotchState{frequency: notch_frequency}
    end

    socket |> put_radio_state(:notch_state, notch_state)
  end

  # notch width
  def dispatch("NW" <> _rest = msg, socket) do
    notch_width = Extract.notch_width(msg)


    notch_state = socket.assigns[:radio_state].notch_state
    |> case do
      %NotchState{} = state ->
        %{state | width: notch_width}
      _ ->
        %NotchState{width: notch_width}
    end

    socket |> put_radio_state(:notch_state, notch_state)
  end

  def dispatch("PC" <> _rest = msg, socket) do
    value = msg |> Extract.power_level()
    socket |> put_radio_state(:power_level, value)
  end

  def dispatch("RG" <> _rest = msg, socket) do
    rf_gain = msg |> Extract.rf_gain()
    socket |> put_radio_state(:rf_gain, rf_gain)
  end

  def dispatch("AG" <> _rest = msg, socket) do
    audio_gain = msg |> Extract.audio_gain()
    socket |> put_radio_state(:audio_gain, audio_gain)
  end

  def dispatch("DD0" <> _rest = msg, socket) do
    data_speed = msg |> Extract.data_speed()
    socket |> put_radio_state(:data_speed, data_speed)
  end

  def dispatch("BSA" <> _rest = msg, socket) do
    avg_level = msg |> Extract.band_scope_avg()
    socket |> put_radio_state(:band_scope_avg, avg_level)
  end

  def dispatch("BSC0" <> _rest = msg, socket) do
    ref_level = msg |> Extract.ref_level()
    socket |> put_radio_state(:ref_level, ref_level)
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

    case socket.assigns.radio_state.band_scope_mode do
      :fixed ->
        socket
        |> put_radio_state(:band_scope_edges, {bs_low, bs_high})
        |> put_radio_state(:band_scope_fixed_span, span)

      :auto_scroll ->
        socket
        |> put_radio_state(:band_scope_edges, {bs_low, bs_high})

      :center ->
        socket

      _ ->
        socket
    end
  end

  # band_scope_mode
  def dispatch("BS3" <> _rest = msg, socket) do
    scope_mode = msg |> Extract.scope_mode()

    socket = socket |> put_radio_state(:band_scope_mode, scope_mode)

    if scope_mode == :center && !is_nil(socket.assigns.radio_state.band_scope_span) do
      band_scope_edges =
        calculate_center_mode_edges(
          socket.assigns.radio_state.active_frequency,
          socket.assigns.radio_state.band_scope_span
        )

      socket |> put_radio_state(:band_scope_edges, band_scope_edges)
    else
      socket
    end
  end

  # band_scope_span
  def dispatch("BS4" <> _rest = msg, socket) do
    scope_span_khz = msg |> Extract.band_scope_span()

    socket = socket |> put_radio_state(:band_scope_span, scope_span_khz)

    case socket.assigns.radio_state.band_scope_mode do
      mode when mode in [:center, :auto_scroll] ->
        band_scope_edges =
          calculate_center_mode_edges(
            socket.assigns.radio_state.active_frequency,
            socket.assigns.radio_state.band_scope_span
          )

        socket |> put_radio_state(:band_scope_edges, band_scope_edges)

      _ ->
        socket
    end
  end

  def dispatch("BS8" <> _rest = msg, socket) do
    socket |> put_radio_state(:band_scope_att, Extract.band_scope_att(msg))
  end

  # VFO A band register
  def dispatch("BU0" <> _rest = msg, socket) do
    band_register = Extract.band_register(msg)
    band_register_state = %{socket.assigns.radio_state.band_register_state | vfo_a_band: band_register}
    socket |> put_radio_state(:band_register_state, band_register_state)
  end

  # VFO B band register
  def dispatch("BU1" <> _rest = msg, socket) do
    band_register = Extract.band_register(msg)
    band_register_state = %{socket.assigns.radio_state.band_register_state | vfo_b_band: band_register}
    socket |> put_radio_state(:band_register_state, band_register_state)
  end

  def dispatch("DS1" <> _rest = msg, socket) do
    socket |> put_radio_state(:display_screen_id, Extract.display_screen_id(msg))
  end

  def dispatch("EX00611" <> _rest = msg, socket) do
    socket
    |> put_radio_state(:ssb_filter_mode, Extract.filter_mode(msg))
  end

  def dispatch("EX00612" <> _rest = msg, socket) do
    socket
    |> put_radio_state(:ssb_data_filter_mode, Extract.filter_mode(msg))
  end

  def dispatch("FA" <> _rest = msg, socket) do
    frequency = msg |> Extract.frequency()
    socket = socket |> put_radio_state(:vfo_a_frequency, frequency)
    previous_active_frequency = socket.assigns.radio_state.active_frequency || 0
    delta = frequency - previous_active_frequency

    socket =
      if socket.assigns.radio_state.active_receiver == :a do
        formatted_frequency = frequency |> RadioViewHelpers.format_raw_frequency()
        formatted_mode = socket.assigns.radio_state.active_mode |> RadioViewHelpers.format_mode()
        page_title = "#{formatted_frequency} - #{formatted_mode}"

        socket
        |> assign(:page_title, page_title)
        |> put_radio_state(:active_frequency, frequency)
        |> put_radio_state(:active_frequency_delta, delta)
      else
        socket
        |> put_radio_state(:inactive_frequency, frequency)
      end

    socket =
      if socket.assigns.radio_state.band_scope_mode == :center && socket.assigns.radio_state.active_receiver == :a do
        band_scope_edges =
          calculate_center_mode_edges(
            socket.assigns.radio_state.active_frequency,
            socket.assigns.radio_state.band_scope_span
          )

        {low, high} = band_scope_edges

        socket
        |> put_radio_state(:band_scope_edges, band_scope_edges)
        |> push_event("freq_delta", %{delta: delta, vfo: "a", bs: %{low: low, high: high}})
      else
        socket
      end

    socket |> vfo_a_updated()
  end

  def dispatch("FB" <> _rest = msg, socket) do
    frequency = msg |> Extract.frequency()
    socket = socket |> put_radio_state(:vfo_b_frequency, frequency)

    previous_active_frequency = socket.assigns.radio_state.active_frequency || 0
    delta = frequency - previous_active_frequency

    socket =
      if socket.assigns.radio_state.active_receiver == :b do
        formatted_frequency = frequency |> RadioViewHelpers.format_raw_frequency()
        formatted_mode = socket.assigns.radio_state.active_mode |> RadioViewHelpers.format_mode()
        page_title = "#{formatted_frequency} - #{formatted_mode}"

        socket
        |> assign(:page_title, page_title)
        |> put_radio_state(:active_frequency, frequency)
        |> put_radio_state(:active_frequency_delta, delta)
      else
        socket
        |> put_radio_state(:inactive_frequency, frequency)
      end

    socket =
      if socket.assigns.radio_state.band_scope_mode == :center && socket.assigns.radio_state.active_receiver == :b do
        band_scope_edges =
          calculate_center_mode_edges(
            socket.assigns.radio_state.active_frequency,
            socket.assigns.radio_state.band_scope_span
          )

        {low, high} = band_scope_edges

        socket
        |> put_radio_state(:band_scope_edges, band_scope_edges)
        |> push_event("freq_delta", %{delta: delta, vfo: "b", bs: %{low: low, high: high}})

      else
        socket
      end

    socket
  end

  def dispatch("FL0" <> _rest = msg, socket) do
    if_filter = msg |> Extract.current_if_filter()
    socket |> put_radio_state(:active_if_filter, if_filter)
  end

  def dispatch("FL1" <> _rest = msg, socket) do
    {filter_id, filter_value} = msg |> Extract.roofing_filter()

    roofing_filter_data =
      socket.assigns.radio_state.roofing_filter_data
      |> Map.put(filter_id, filter_value)

    socket |> put_radio_state(:roofing_filter_data, roofing_filter_data)
  end

  def dispatch("FR0", socket) do
    socket
    |> put_radio_state(:active_receiver, :a)
    |> put_radio_state(:active_frequency, socket.assigns.radio_state.vfo_a_frequency)
    |> put_radio_state(:inactive_receiver, :b)
    |> put_radio_state(:inactive_frequency, socket.assigns.radio_state.vfo_b_frequency)
  end

  def dispatch("FR1", socket) do
    socket
    |> put_radio_state(:active_receiver, :b)
    |> put_radio_state(:active_frequency, socket.assigns.radio_state.vfo_b_frequency)
    |> put_radio_state(:inactive_receiver, :a)
    |> put_radio_state(:inactive_frequency, socket.assigns.radio_state.vfo_a_frequency)
  end

  def dispatch("OM0" <> _rest = msg, socket) do
    frequency = socket.assigns.radio_state.active_frequency

    mode = msg |> Extract.operating_mode()

    formatted_frequency = frequency |> RadioViewHelpers.format_raw_frequency()
    formatted_mode = mode |> RadioViewHelpers.format_mode()
    page_title = "#{formatted_frequency} - #{formatted_mode}"

    socket
    |> put_radio_state(:active_mode, mode)
    |> assign(:page_title, page_title)
  end

  def dispatch("OM1" <> _rest = msg, socket) do
    socket |> put_radio_state(:inactive_mode, Extract.operating_mode(msg))
  end

  def dispatch("PA" <> _rest = msg, socket) do
    socket |> put_radio_state(:rf_pre, Extract.rf_pre(msg))
  end

  def dispatch("RA" <> _rest = msg, socket) do
    rf_att = msg |> Extract.rf_att()
    socket |> put_radio_state(:rf_att, rf_att)
  end

  def dispatch("RM1" <> _rest = msg, socket) do
    meter = msg |> Extract.alc_meter()
    socket |> put_radio_state(:alc_meter, meter)
  end

  def dispatch("RM2" <> _rest = msg, socket) do
    meter = msg |> Extract.swr_meter()
    socket |> put_radio_state(:swr_meter, meter)
  end

  def dispatch("RM3" <> _rest = msg, socket) do
    meter = msg |> Extract.comp_meter()
    socket |> put_radio_state(:comp_meter, meter)
  end

  def dispatch("RM4" <> _rest = msg, socket) do
    meter = msg |> Extract.id_meter()
    socket |> put_radio_state(:id_meter, meter)
  end

  def dispatch("RM5" <> _rest = msg, socket) do
    meter = msg |> Extract.vd_meter()
    socket |> put_radio_state(:vd_meter, meter)
  end

  def dispatch("RM6" <> _rest = msg, socket) do
    meter = msg |> Extract.temp_meter()
    socket |> put_radio_state(:temp_meter, meter)
  end

  def dispatch("SH0" <> _rest = msg, socket) do
    %{
      active_mode: active_mode,
      ssb_filter_mode: ssb_filter_mode,
      ssb_data_filter_mode: ssb_data_filter_mode,
      filter_state: filter_state
    } = socket.assigns.radio_state

    filter_mode = case active_mode do
      ssb when ssb in [:usb, :lsb] -> ssb_filter_mode
      data when data in [:usb_d, :lsb_d] -> ssb_data_filter_mode
      _ -> :unknown
    end

    passband_id = Extract.passband_id(msg)

    filter_hi_shift =
      passband_id |> Extract.filter_hi_shift(filter_mode, active_mode)

    filter_state = %{filter_state | hi_shift: filter_hi_shift, hi_passband_id: passband_id}

    socket
    |> put_radio_state(:filter_state, filter_state)
    |> update_filter_hi_edge()
  end

  def dispatch("SL0" <> _rest = msg, socket) do
    %{
      active_mode: active_mode,
      ssb_filter_mode: ssb_filter_mode,
      ssb_data_filter_mode: ssb_data_filter_mode,
      filter_state: filter_state
    } = socket.assigns.radio_state

    filter_mode = case active_mode do
      ssb when ssb in [:usb, :lsb] -> ssb_filter_mode
      data when data in [:usb_d, :lsb_d] -> ssb_data_filter_mode
      _ -> :unknown
    end

    passband_id = Extract.passband_id(msg)

    filter_lo_width =
      passband_id |> Extract.filter_lo_width(filter_mode, active_mode)

    filter_state = %{filter_state | lo_width: filter_lo_width, lo_passband_id: passband_id}

    socket
    |> put_radio_state(:filter_state, filter_state)
    |> update_filter_lo_edge()
  end

  def dispatch("SM" <> _rest = msg, socket) do
    socket |> put_radio_state(:s_meter, Extract.s_meter(msg))
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
      filter_state: filter_state
    } = socket.assigns.radio_state

    active_frequency = socket |> get_active_receiver_frequency()

    case active_mode do
      mode when active_mode in [:lsb, :usb, :cw, :cw_r] ->
        socket
        |> put_radio_state(
          :filter_high_freq,
          RadioViewHelpers.offset_frequency(mode, active_frequency, filter_state.hi_shift)
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
      filter_state: filter_state
    } = socket.assigns.radio_state

    active_frequency = socket |> get_active_receiver_frequency()

    case active_mode do
      mode when active_mode in [:lsb, :usb, :cw, :cw_r] ->
        socket
        |> put_radio_state(
          :filter_low_freq,
          RadioViewHelpers.offset_frequency_reverse(mode, active_frequency, filter_state.lo_width)
        )

      _ ->
        socket
    end
  end

  defp get_active_receiver_frequency(socket) do
    socket.assigns.radio_state.active_receiver
    |> case do
      :a -> socket.assigns.radio_state.vfo_a_frequency
      :b -> socket.assigns.radio_state.vfo_b_frequency
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

  def put_radio_state(socket, key, var) do
    radio_state = socket.assigns[:radio_state] || %RadioState{}

    new_state = radio_state |> Map.put(key, var)
    socket |> assign(:radio_state, new_state)
  end
end
