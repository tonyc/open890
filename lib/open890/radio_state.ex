defmodule Open890.RadioState do
  require Logger

  alias Open890.{AntennaState, BandRegisterState, FilterState, NoiseBlankState, NotchState, TransverterState}
  alias Open890.Extract
  alias Open890Web.RadioViewHelpers

  defstruct [
    active_frequency: 0,
    active_frequency_delta: 0,
    active_if_filter: nil,
    active_mode: :unknown,
    active_receiver: :a,
    active_transmitter: :a,
    agc: nil,
    alc_meter: 0,
    antenna_state: %AntennaState{},
    apf_enabled: nil,
    audio_gain: nil,
    band_register_state: %BandRegisterState{},
    band_scope_att: nil,
    band_scope_avg: nil,
    band_scope_edges: nil,
    band_scope_fixed_span: nil,
    band_scope_mode: nil,
    band_scope_span: nil,
    bc: nil,
    comp_meter: 0,
    cw_delay: nil,
    cw_key_speed: nil,
    data_speed: nil,
    display_screen_id: 0,
    filter_high_freq: nil,
    filter_low_freq: nil,
    filter_state: %FilterState{},
    id_meter: 0,
    inactive_frequency: "",
    inactive_mode: :unknown,
    inactive_receiver: :b,
    mic_gain: nil,
    noise_blank_state: %NoiseBlankState{},
    notch_state: %NotchState{},
    nr: nil,
    power_level: nil,
    projected_active_receiver_location: "",
    ref_level: 40,
    rf_att: 0,
    rf_gain: nil,
    rf_pre: 0,
    roofing_filter_data: %{a: nil, b: nil, c: nil},
    s_meter: 0,
    squelch: nil,
    ssb_data_filter_mode: nil,
    ssb_filter_mode: nil,
    swr_meter: 0,
    split_enabled: false,
    temp_meter: 0,
    transverter_state: %TransverterState{},
    tx_state: :off,
    vd_meter: 0,
    vfo_a_frequency: nil,
    vfo_b_frequency: nil,
    vfo_memory_state: nil,
    voip_available: nil,
    voip_enabled: nil,
  ]

  def dispatch("##VP1" <> _ = _msg, %__MODULE__{} = state) do
    %{state | voip_enabled: true}
  end

  def dispatch("##VP0" <> _ = _msg, %__MODULE__{} = state) do
    %{state | voip_enabled: false}
  end

  def dispatch("##KN21" <> _ = _msg, %__MODULE__{} = state) do
    %{state | voip_available: true}
  end

  def dispatch("##KN20" <> _ = _msg, %__MODULE__{} = state) do
    %{state | voip_available: false}
  end

  def dispatch("AP0" <> _ = msg, %__MODULE__{} = state) do
    %{state | apf_enabled: Extract.apf_enabled(msg)}
  end

  def dispatch("TB" <> _ = msg, %__MODULE__{} = state) do
    %{state | split_enabled: Extract.split_enabled(msg)}
  end

  def dispatch("SQ" <> _ = msg, %__MODULE__{} = state) do
    %{state | squelch: Extract.sql(msg)}
  end

  def dispatch("GC" <> _ = msg, %__MODULE__{} = state) do
    %{state | agc: Extract.agc(msg)}
  end

  def dispatch("NR" <> _ = msg, %__MODULE__{} = state) do
    %{state | nr: Extract.nr(msg)}
  end

  def dispatch("BC" <> _ = msg, %__MODULE__{} = state) do
    %{state | bc: Extract.bc(msg)}
  end

  def dispatch("MG" <> _ = msg, %__MODULE__{} = state) do
    %{state | mic_gain: Extract.mic_gain(msg)}
  end

  def dispatch("TX0", %__MODULE__{} = state) do
    %{state | tx_state: :send}
  end

  def dispatch("TX1", %__MODULE__{} = state) do
    %{state | tx_state: :data_send}
  end

  def dispatch("TX2", %__MODULE__{} = state) do
    %{state | tx_state: :tx_tune}
  end

  def dispatch("RX" = _msg, %__MODULE__{} = state) do
    %{state | tx_state: :off}
  end

  def dispatch("SD" <> _ = msg, %__MODULE__{} = state) do
    %{state | cw_delay: Extract.cw_delay(msg)}
  end

  def dispatch("KS" <> _ = msg, %__MODULE__{} = state) do
    %{state | cw_key_speed: Extract.key_speed(msg)}
  end

  def dispatch("AN" <> _ = msg, %__MODULE__{} = state) do
    %{state | antenna_state: Extract.antenna_state(msg)}
  end

  def dispatch("XV" <> _ = msg, %__MODULE__{} = state) do
    value = msg |> Extract.transverter_enabled()

    new_transverter_state = state.transverter_state
    |> case do
      %TransverterState{} = t_state ->
        %{t_state | enabled: value}
      _ ->
        %TransverterState{enabled: value}
    end

    %{state | transverter_state: new_transverter_state}
  end

  def dispatch("XO" <> _ = msg, %__MODULE__{} = state) do
    value = msg |> Extract.transverter_offset()

    new_transverter_state = state.transverter_state
    |> case do
      %TransverterState{} = xv_state ->
        %{xv_state | offset: value}
      _ ->
        %TransverterState{offset: value}
    end

    %{state | transverter_state: new_transverter_state}
  end

  def dispatch("MV" <> _ = msg, %__MODULE__{} = state) do
    %{state | vfo_memory_state: Extract.vfo_memory_state(msg)}
  end

  def dispatch("NB1" <> _ = msg, %__MODULE__{} = state) do
    enabled = msg |> Extract.nb_enabled()

    new_nb_state = state.noise_blank_state
    |> case do
      %NoiseBlankState{} = nb_state ->
        %{nb_state | nb_1_enabled: enabled}

      _ -> %NoiseBlankState{nb_1_enabled: enabled}
    end

    %{state | noise_blank_state: new_nb_state}
  end

  def dispatch("NB2" <> _ = msg, %__MODULE__{} = state) do
    enabled = msg |> Extract.nb_enabled()

    new_nb_state = state.noise_blank_state
    |> case do
      %NoiseBlankState{} = nb_state ->
        %{nb_state | nb_2_enabled: enabled}

      _ -> %NoiseBlankState{nb_2_enabled: enabled}
    end

    %{state | noise_blank_state: new_nb_state}
  end

  # Notch on/off
  def dispatch("NT" <> _ = msg, %__MODULE__{} = state) do
    notch_enabled = msg |> Extract.notch_state()

    new_notch_state = state.notch_state
    |> case do
      %NotchState{} = notch_state ->
        %{notch_state | enabled: notch_enabled}

      _ ->
        %NotchState{enabled: notch_enabled}
    end

    %{state | notch_state: new_notch_state}
  end

  # notch frequency
  def dispatch("BP" <> _ = msg, %__MODULE__{} = state) do
    notch_frequency = Extract.notch_filter(msg)

    new_notch_state = state.notch_state
    |> case do
      %NotchState{} = notch_state ->
        %{notch_state | frequency: notch_frequency}
      _ ->
        %NotchState{frequency: notch_frequency}
    end

    %{state | notch_state: new_notch_state}
  end

  # notch width
  def dispatch("NW" <> _ = msg, %__MODULE__{} = state) do
    notch_width = Extract.notch_width(msg)

    new_notch_state = state.notch_state
    |> case do
      %NotchState{} = notch_state ->
        %{notch_state | width: notch_width}
      _ ->
        %NotchState{width: notch_width}
    end

    %{state | notch_state: new_notch_state}
  end

  def dispatch("PC" <> _ = msg, %__MODULE__{} = state) do
    %{state | power_level: Extract.power_level(msg)}
  end

  def dispatch("RG" <> _ = msg, %__MODULE__{} = state) do
    %{state | rf_gain: Extract.rf_gain(msg)}
  end

  def dispatch("AG" <> _ = msg, %__MODULE__{} = state) do
    %{state | audio_gain: Extract.audio_gain(msg)}
  end

  def dispatch("DD0" <> _ = msg, %__MODULE__{} = state) do
    %{state | data_speed: Extract.data_speed(msg)}
  end

  def dispatch("BSA" <> _ = msg, %__MODULE__{} = state) do
    %{state | band_scope_avg: Extract.band_scope_avg(msg)}
  end

  def dispatch("BSC0" <> _ = msg, %__MODULE__{} = state) do
    %{state | ref_level: Extract.ref_level(msg)}
  end

  def dispatch("BSM0" <> _ = msg, %__MODULE__{} = state) do
    [bs_low, bs_high] = msg |> Extract.band_edges()

    [low_int, high_int] =
      [bs_low, bs_high]
      |> Enum.map(&Kernel.div(&1, 1000))

    span =
      (high_int - low_int)
      |> to_string()
      |> String.trim_leading("0")
      |> String.to_integer()

    case state.band_scope_mode do
      :fixed ->
        %{state |
          band_scope_edges: {bs_low, bs_high},
          band_scope_fixed_span: span
        }

      :auto_scroll ->
        %{state | band_scope_edges: {bs_low, bs_high}}

      _ ->
        state
    end
  end

  # band_scope_mode
  def dispatch("BS3" <> _ = msg, %__MODULE__{} = state) do
    scope_mode = msg |> Extract.scope_mode()

    state = %{state | band_scope_mode: scope_mode}

    if scope_mode == :center && !is_nil(state.band_scope_span) do
      band_scope_edges =
        calculate_center_mode_edges(
          state.active_frequency,
          state.band_scope_span
        )

      %{state | band_scope_edges: band_scope_edges}
    else
      state
    end
  end

  # band_scope_span
  def dispatch("BS4" <> _ = msg, %__MODULE__{} = state) do
    scope_span_khz = msg |> Extract.band_scope_span()

    state = %{state | band_scope_span: scope_span_khz}

    case state.band_scope_mode do
      mode when mode in [:center, :auto_scroll] ->
        band_scope_edges =
          calculate_center_mode_edges(
            state.active_frequency,
            state.band_scope_span
          )

        %{state | band_scope_edges: band_scope_edges}
      _ ->
        state
    end
  end

  def dispatch("BS8" <> _ = msg, %__MODULE__{} = state) do
    %{state | band_scope_att: Extract.band_scope_att(msg)}
  end

  # VFO A band register
  def dispatch("BU0" <> _ = msg, %__MODULE__{} = state) do
    band_register = Extract.band_register(msg)
    band_register_state = %{state.band_register_state | vfo_a_band: band_register}

    %{state | band_register_state: band_register_state}
  end

  # VFO B band register
  def dispatch("BU1" <> _ = msg, %__MODULE__{} = state) do
    band_register = Extract.band_register(msg)

    band_register_state = %{state.band_register_state | vfo_b_band: band_register}
    %{state | band_register_state: band_register_state}
  end

  def dispatch("DS1" <> _ = msg, %__MODULE__{} = state) do
    %{state | display_screen_id: Extract.display_screen_id(msg)}
  end

  def dispatch("EX00611" <> _ = msg, %__MODULE__{} = state) do
    %{state | ssb_filter_mode: Extract.filter_mode(msg)}
  end

  def dispatch("EX00612" <> _ = msg, %__MODULE__{} = state) do
    %{state | ssb_data_filter_mode: Extract.filter_mode(msg)}
  end

  def dispatch("FA" <> _ = msg, %__MODULE__{} = state) do
    frequency = msg |> Extract.frequency()
    state = %{state | vfo_a_frequency: frequency}
    previous_active_frequency = state.active_frequency || 0
    delta = frequency - previous_active_frequency

    state =
      if state.active_receiver == :a do
        %{state |
          active_frequency: frequency,
          active_frequency_delta: delta
        }
      else
        %{state | inactive_frequency: frequency}
      end

    state =
      if state.band_scope_mode == :center && state.active_receiver == :a do
        band_scope_edges =
          calculate_center_mode_edges(
            state.active_frequency,
            state.band_scope_span
          )

        %{state | band_scope_edges: band_scope_edges}
      else
        state
      end

    state |> vfo_a_updated()
  end

  def dispatch("FB" <> _ = msg, %__MODULE__{} = state) do
    frequency = msg |> Extract.frequency()
    state = %{state | vfo_b_frequency: frequency}

    previous_active_frequency = state.active_frequency || 0
    delta = frequency - previous_active_frequency

    state =
      if state.active_receiver == :b do
        %{state |
          active_frequency: frequency,
          active_frequency_delta: delta
        }
      else
        %{state | inactive_frequency: frequency}
      end

    state =
      if state.band_scope_mode == :center && state.active_receiver == :b do
        band_scope_edges =
          calculate_center_mode_edges(
            state.active_frequency,
            state.band_scope_span
          )

        %{state | band_scope_edges: band_scope_edges}

      else
        state
      end

    state
  end

  def dispatch("FL0" <> _ = msg, %__MODULE__{} = state) do
    %{state | active_if_filter: Extract.current_if_filter(msg)}
  end

  def dispatch("FL1" <> _ = msg, %__MODULE__{} = state) do
    {filter_id, filter_value} = msg |> Extract.roofing_filter()

    roofing_filter_data =
      state.roofing_filter_data
      |> Map.put(filter_id, filter_value)

    %{state | roofing_filter_data: roofing_filter_data}
  end

  def dispatch("FR0", %__MODULE__{} = state) do
    %{state |
      active_receiver: :a,
      active_frequency: state.vfo_a_frequency,
      inactive_receiver: :b,
      inactive_frequency: state.vfo_b_frequency
    }
  end

  def dispatch("FR1", %__MODULE__{} = state) do
    %{state |
      active_receiver: :b,
      active_frequency: state.vfo_b_frequency,
      inactive_receiver: :a,
      inactive_frequency: state.vfo_a_frequency
    }
  end

  # Primary operating mode changed
  def dispatch("OM0" <> _ = msg, %__MODULE__{} = state) do
    %{state | active_mode: Extract.operating_mode(msg)}
  end

  def dispatch("OM1" <> _ = msg, %__MODULE__{} = state) do
    %{state | inactive_mode: Extract.operating_mode(msg)}
  end

  def dispatch("PA" <> _ = msg, %__MODULE__{} = state) do
    %{state | rf_pre: Extract.rf_pre(msg)}
  end

  def dispatch("RA" <> _ = msg, %__MODULE__{} = state) do
    %{state | rf_att: Extract.rf_att(msg)}
  end

  def dispatch("RM1" <> _ = msg, %__MODULE__{} = state) do
    %{state | alc_meter: Extract.alc_meter(msg)}
  end

  def dispatch("RM2" <> _ = msg, %__MODULE__{} = state) do
    %{state | swr_meter: Extract.swr_meter(msg)}
  end

  def dispatch("RM3" <> _ = msg, %__MODULE__{} = state) do
    %{state | comp_meter: Extract.comp_meter(msg)}
  end

  def dispatch("RM4" <> _ = msg, %__MODULE__{} = state) do
    %{state | id_meter: Extract.id_meter(msg)}
  end

  def dispatch("RM5" <> _ = msg, %__MODULE__{} = state) do
    %{state | vd_meter: Extract.vd_meter(msg)}
  end

  def dispatch("RM6" <> _ = msg, %__MODULE__{} = state) do
    %{state | temp_meter: Extract.temp_meter(msg)}
  end

  def dispatch("SH0" <> _ = msg, %__MODULE__{} = state) do
    %{
      active_mode: active_mode,
      ssb_filter_mode: ssb_filter_mode,
      ssb_data_filter_mode: ssb_data_filter_mode,
      filter_state: filter_state
    } = state

    filter_mode = case active_mode do
      ssb when ssb in [:usb, :lsb] -> ssb_filter_mode
      data when data in [:usb_d, :lsb_d] -> ssb_data_filter_mode
      _ -> :unknown
    end

    passband_id = Extract.passband_id(msg)

    filter_hi_shift =
      passband_id |> Extract.filter_hi_shift(filter_mode, active_mode)

    filter_state = %{filter_state | hi_shift: filter_hi_shift, hi_passband_id: passband_id}

    %{state | filter_state: filter_state}
    |> update_filter_hi_edge()

  end

  def dispatch("SL0" <> _ = msg, %__MODULE__{} = state) do
    %{
      active_mode: active_mode,
      ssb_filter_mode: ssb_filter_mode,
      ssb_data_filter_mode: ssb_data_filter_mode,
      filter_state: filter_state
    } = state

    filter_mode = case active_mode do
      ssb when ssb in [:usb, :lsb] -> ssb_filter_mode
      data when data in [:usb_d, :lsb_d] -> ssb_data_filter_mode
      _ -> :unknown
    end

    passband_id = Extract.passband_id(msg)

    filter_lo_width =
      passband_id |> Extract.filter_lo_width(filter_mode, active_mode)

    filter_state = %{filter_state | lo_width: filter_lo_width, lo_passband_id: passband_id}

    %{state | filter_state: filter_state}
    |> update_filter_lo_edge()
  end

  def dispatch("SM" <> _ = msg, %__MODULE__{} = state) do
    %{state | s_meter: Extract.s_meter(msg)}
  end

  ## dispatch catchall - this needs to be the very last one
  def dispatch(msg, %__MODULE__{} = state) do
    Logger.debug("Dispatch: unknown message: #{inspect(msg)}")

    state
  end

  ### END dispatching

  ### everything under here is used by the dispatch functions
  def vfo_a_updated(%__MODULE__{} = state) do
    state
    |> update_filter_hi_edge()
    |> update_filter_lo_edge()
  end

  def update_filter_hi_edge(%__MODULE__{} = state) do
    %{
      active_mode: active_mode,
      ssb_filter_mode: _ssb_filter_mode,
      ssb_data_filter_mode: _ssb_data_filter_mode,
      filter_state: filter_state
    } = state

    active_frequency = state |> get_active_receiver_frequency()

    case active_mode do
      mode when active_mode in [:lsb, :usb, :cw, :cw_r] ->
        offset_freq = RadioViewHelpers.offset_frequency(mode, active_frequency, filter_state.hi_shift)
        %{state | filter_high_freq: offset_freq}
      _ ->
        state
    end
  end

  def update_filter_lo_edge(%__MODULE__{} = state) do
    %{
      active_mode: active_mode,
      ssb_filter_mode: _ssb_filter_mode,
      ssb_data_filter_mode: _ssb_data_filter_mode,
      filter_state: filter_state
    } = state

    active_frequency = state |> get_active_receiver_frequency()

    case active_mode do
      mode when active_mode in [:lsb, :usb, :cw, :cw_r] ->
        filter_low_freq = RadioViewHelpers.offset_frequency_reverse(mode, active_frequency, filter_state.lo_width)


        %{state | filter_low_freq: filter_low_freq}
      _ ->
        state
    end
  end

  def get_active_receiver_frequency(%__MODULE__{active_receiver: active_receiver, vfo_a_frequency: vfo_a_frequency, vfo_b_frequency: vfo_b_frequency}) do
    case active_receiver do
      :a -> vfo_a_frequency
      :b -> vfo_b_frequency
    end
  end

  def calculate_center_mode_edges(freq, span_khz)
       when is_integer(freq) and is_integer(span_khz) do
    span = span_khz * 1000
    half_span = span |> div(2)

    bs_low = freq - half_span
    bs_high = freq + half_span

    {bs_low, bs_high}
  end

  def filter_mode(%__MODULE__{} = radio_state) do
    case radio_state.active_mode do
      ssb when ssb in [:usb, :lsb] ->
        radio_state.ssb_filter_mode

      ssb_data when ssb_data in [:usb_d, :lsb_d] ->
        radio_state.ssb_data_filter_mode

      _ ->
        nil
    end
  end

  def active_frequency(%__MODULE__{} = radio_state) do
    case radio_state.active_receiver do
      :a -> radio_state.vfo_a_frequency
      :b -> radio_state.vfo_b_frequency
      _ -> nil
    end
  end

end
