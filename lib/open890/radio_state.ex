defmodule Open890.RadioState do
  require Logger

  # FIXME: Change this to `use ExtractCommand`
  require ExtractCommand
  import ExtractCommand

  alias Open890.{
    AntennaState,
    BandRegisterState,
    Extract,
    FilterState,
    NoiseBlankState,
    NotchState,
    TransverterState,
    TunerState
  }

  alias Open890Web.RadioViewHelpers

  defstruct active_frequency: 0,
            active_frequency_delta: 0,
            active_if_filter: nil,
            active_mode: nil,
            active_receiver: :a,
            active_transmitter: :a,
            inactive_frequency: 0,
            inactive_mode: nil,
            inactive_receiver: :b,
            memory_channel_frequency: nil,
            memory_channel_number: nil,
            memory_channel_inactive_frequency: nil,
            memory_channel_active_mode: nil,
            memory_channel_inactive_mode: nil,
            agc: nil,
            agc_off: nil,
            alc_meter: 0,
            antenna_state: %AntennaState{},
            apf_enabled: nil,
            audio_gain: nil,
            band_register_state: %BandRegisterState{},
            band_scope_att: nil,
            band_scope_avg: nil,
            band_scope_edges: nil,
            band_scope_fixed_edges: nil,
            band_scope_expand: false,
            band_scope_fixed_range_number: nil,
            band_scope_mode: nil,
            band_scope_span: nil,
            bc: nil,
            busy_enabled: false,
            comp_meter: 0,
            cw_delay: nil,
            cw_key_speed: nil,
            data_speed: 1,
            display_screen_id: 0,
            filter_high_freq: nil,
            filter_low_freq: nil,
            filter_state: %FilterState{},
            fine: nil,
            id_meter: 0,
            lock_enabled: false,
            mhz_enabled: false,
            mic_gain: nil,
            noise_blank_state: %NoiseBlankState{},
            notch_state: %NotchState{},
            nr: nil,
            power_level: nil,
            proc_enabled: false,
            proc_input: 0,
            proc_output: 0,
            projected_active_receiver_location: "",
            ref_level: 40,
            rf_att: 0,
            rf_gain: nil,
            rf_pre: 0,
            roofing_filter_data: %{a: nil, b: nil, c: nil},
            s_meter: 0,
            split_enabled: false,
            squelch: nil,
            ssb_data_filter_mode: nil,
            ssb_filter_mode: nil,
            swr_meter: 0,
            temp_meter: 0,
            transverter_state: %TransverterState{},
            tuner_state: %TunerState{},
            tf_set_enabled: false,
            tf_set_marker_frequency: nil,
            tx_state: :off,
            vd_meter: 0,
            vfo_a_frequency: nil,
            vfo_b_frequency: nil,
            vfo_memory_state: nil,
            voip_available: nil,
            voip_enabled: nil,
            rit_enabled: false,
            xit_enabled: false,
            rit_xit_offset: 0

  extract "##KN2", :voip_available, as: :boolean
  extract "##VP", :voip_enabled, as: :boolean

  extract "AC", :tuner_state
  extract "AG", :audio_gain
  extract "AN", :antenna_state
  extract "AP0", :apf_enabled
  extract "BC", :bc
  extract "BSA", :band_scope_avg
  extract "BSC0", :ref_level
  extract "BSO", :band_scope_expand, as: :boolean
  extract "BS5", :band_scope_fixed_range_number
  extract "BS8", :band_scope_att
  extract "BY", :busy_enabled, as: :boolean
  extract "DD0", :data_speed
  extract "DS1", :display_screen_id
  extract "LK", :lock_enabled, as: :boolean
  extract "MG", :mic_gain
  extract "MH", :mhz_enabled, as: :boolean
  extract "MN", :memory_channel_number
  # extract "MV", :vfo_memory_state
  extract "NR", :nr
  extract "PA", :rf_pre
  extract "PC", :power_level
  extract "PR", :proc_enabled, as: :boolean
  extract "RA", :rf_att
  extract "RF", :rit_xit_offset
  extract "RG", :rf_gain
  extract "RM1", :alc_meter
  extract "RM2", :swr_meter
  extract "RM3", :comp_meter
  extract "RM4", :id_meter
  extract "RM5", :vd_meter
  extract "RM6", :temp_meter
  extract "RT", :rit_enabled, as: :boolean
  extract "SD", :cw_delay
  extract "SM", :s_meter
  extract "SQ", :squelch
  extract "TB", :split_enabled
  extract "XT", :xit_enabled, as: :boolean

  defp swap_a_b(state) do
    if state.active_receiver == :a do
      state |> dispatch("FR1")
    else
      state |> dispatch("FR0")
    end
  end

  def dispatch(%__MODULE__{} = state, "PL" <> _ = msg) do
    {proc_input, proc_output} = Extract.proc_levels(msg)

    %{state | proc_input: proc_input, proc_output: proc_output}
  end

  def dispatch(%__MODULE__{} = state, "TS" <> _ = msg) do
    tf_set_enabled = Extract.boolean(msg)

    # swap A/B if split is enabled
    # otherwise, if XIT is enabled:
    # if enabling:
    #   effective_active_frequency = effective_inactive_frequency
    # else:
    #   subtract the offset from the active_frequency

    marker_frequency = if tf_set_enabled do
      effective_active_frequency(state)
    else
      nil
    end

    state = if state.split_enabled do
      swap_a_b(state)
    else
      state
    end

    %{state | tf_set_enabled: tf_set_enabled, tf_set_marker_frequency: marker_frequency}
  end

  def dispatch(%__MODULE__{} = state, "MV" <> _ = msg) do
    # FIXME: somehow we need to always query the operating mode, because the radio does not always send the mode
    # when switching between vfo/memory if it matches
    vfo_memory_state = Extract.vfo_memory_state(msg)

    %{state | vfo_memory_state: vfo_memory_state}
  end

  def dispatch(%__MODULE__{} = state, "MA70" <> _ = msg) do
    %{
      state
      | memory_channel_frequency: Extract.memory_channel_frequency(msg),

        # clear out the inactive side because the radio doesn't specifically tell us it cleared out.
        # just wait for a new MA71 to tell us the inactive side.
        memory_channel_inactive_frequency: nil
    }
  end

  def dispatch(%__MODULE__{} = state, "MA71" <> _ = msg) do
    %{state | memory_channel_inactive_frequency: Extract.memory_channel_frequency(msg)}
  end

  def dispatch(%__MODULE__{} = state, "FS00" <> _ = _msg) do
    %{state | fine: false}
  end

  def dispatch(%__MODULE__{} = state, "FS11" <> _ = _msg) do
    %{state | fine: true}
  end

  def dispatch(%__MODULE__{} = state, "GC0" <> _ = _msg) do
    %{state | agc_off: true}
  end

  def dispatch(%__MODULE__{} = state, "GC" <> _ = msg) do
    %{state | agc: Extract.agc(msg), agc_off: false}
  end

  def dispatch(%__MODULE__{} = state, "TX0") do
    %{state | tx_state: :send}
  end

  def dispatch(%__MODULE__{} = state, "TX1") do
    %{state | tx_state: :data_send}
  end

  def dispatch(%__MODULE__{} = state, "TX2") do
    %{state | tx_state: :tx_tune}
  end

  def dispatch(%__MODULE__{} = state, "RX" = _msg) do
    %{state | tx_state: :off}
  end

  def dispatch(%__MODULE__{} = state, "KS" <> _ = msg) do
    %{state | cw_key_speed: Extract.key_speed(msg)}
  end

  def dispatch(%__MODULE__{} = state, "XV" <> _ = msg) do
    value = msg |> Extract.transverter_enabled()

    new_transverter_state =
      state.transverter_state
      |> case do
        %TransverterState{} = t_state ->
          %{t_state | enabled: value}

        _ ->
          %TransverterState{enabled: value}
      end

    %{state | transverter_state: new_transverter_state}
  end

  def dispatch(%__MODULE__{} = state, "XO" <> _ = msg) do
    value = msg |> Extract.transverter_offset()

    new_transverter_state =
      state.transverter_state
      |> case do
        %TransverterState{} = xv_state ->
          %{xv_state | offset: value}

        _ ->
          %TransverterState{offset: value}
      end

    %{state | transverter_state: new_transverter_state}
  end

  def dispatch(%__MODULE__{} = state, "NB1" <> _ = msg) do
    enabled = msg |> Extract.nb_enabled()

    new_nb_state =
      state.noise_blank_state
      |> case do
        %NoiseBlankState{} = nb_state ->
          %{nb_state | nb_1_enabled: enabled}

        _ ->
          %NoiseBlankState{nb_1_enabled: enabled}
      end

    %{state | noise_blank_state: new_nb_state}
  end

  def dispatch(%__MODULE__{} = state, "NB2" <> _ = msg) do
    enabled = msg |> Extract.nb_enabled()

    new_nb_state =
      state.noise_blank_state
      |> case do
        %NoiseBlankState{} = nb_state ->
          %{nb_state | nb_2_enabled: enabled}

        _ ->
          %NoiseBlankState{nb_2_enabled: enabled}
      end

    %{state | noise_blank_state: new_nb_state}
  end

  # Notch on/off
  def dispatch(%__MODULE__{} = state, "NT" <> _ = msg) do
    notch_enabled = msg |> Extract.notch_state()

    new_notch_state =
      state.notch_state
      |> case do
        %NotchState{} = notch_state ->
          %{notch_state | enabled: notch_enabled}

        _ ->
          %NotchState{enabled: notch_enabled}
      end

    %{state | notch_state: new_notch_state}
  end

  # notch frequency
  def dispatch(%__MODULE__{} = state, "BP" <> _ = msg) do
    notch_frequency = Extract.notch_filter(msg)

    new_notch_state =
      state.notch_state
      |> case do
        %NotchState{} = notch_state ->
          %{notch_state | frequency: notch_frequency}

        _ ->
          %NotchState{frequency: notch_frequency}
      end

    %{state | notch_state: new_notch_state}
  end

  # notch width
  def dispatch(%__MODULE__{} = state, "NW" <> _ = msg) do
    notch_width = Extract.notch_width(msg)

    new_notch_state =
      state.notch_state
      |> case do
        %NotchState{} = notch_state ->
          %{notch_state | width: notch_width}

        _ ->
          %NotchState{width: notch_width}
      end

    %{state | notch_state: new_notch_state}
  end

  # band_scope_edges, band_scope_fixed_edges
  def dispatch(%__MODULE__{} = state, "BSM0" <> _ = msg) do
    [bs_low, bs_high] = msg |> Extract.band_edges()

    edges = {bs_low, bs_high}

    case state.band_scope_mode do
      :fixed ->
        %{state | band_scope_fixed_edges: edges, band_scope_edges: edges}

      :auto_scroll ->
        %{state | band_scope_edges: edges}

      _ ->
        state
    end
  end

  # band_scope_mode
  def dispatch(%__MODULE__{} = state, "BS3" <> _ = msg) do
    scope_mode = msg |> Extract.scope_mode()

    state = %{state | band_scope_mode: scope_mode}

    state =
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

    state
  end

  # band_scope_span
  def dispatch(%__MODULE__{} = state, "BS4" <> _ = msg) do
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

  # VFO A band register
  def dispatch(%__MODULE__{} = state, "BU0" <> _ = msg) do
    band_register = Extract.band_register(msg)
    band_register_state = %{state.band_register_state | vfo_a_band: band_register}

    %{state | band_register_state: band_register_state}
  end

  # VFO B band register
  def dispatch(%__MODULE__{} = state, "BU1" <> _ = msg) do
    band_register = Extract.band_register(msg)

    band_register_state = %{state.band_register_state | vfo_b_band: band_register}
    %{state | band_register_state: band_register_state}
  end

  def dispatch(%__MODULE__{} = state, "EX00611" <> _ = msg) do
    %{state | ssb_filter_mode: Extract.filter_mode(msg)}
  end

  def dispatch(%__MODULE__{} = state, "EX00612" <> _ = msg) do
    %{state | ssb_data_filter_mode: Extract.filter_mode(msg)}
  end

  def dispatch(%__MODULE__{} = state, "FA" <> _ = msg) do
    frequency = msg |> Extract.frequency()
    state = %{state | vfo_a_frequency: frequency}

    previous_active_frequency = effective_active_frequency(state) || 0

    # TC - possibly need to subtract the RIT offset if enabled?
    delta = frequency - previous_active_frequency

    delta = if state.rit_enabled do
      delta + state.rit_xit_offset
    else
      delta
    end

    state =
      if state.active_receiver == :a do
        %{state | active_frequency: frequency, active_frequency_delta: delta}
      else
        %{state | inactive_frequency: frequency}
      end

    state =
      if state.band_scope_mode == :center && state.active_receiver == :a do
        band_scope_edges =
          calculate_center_mode_edges(
            effective_active_frequency(state),
            state.band_scope_span
          )

        %{state | band_scope_edges: band_scope_edges}
      else
        state
      end

    state |> vfo_a_updated()
  end

  def dispatch(%__MODULE__{} = state, "FB" <> _ = msg) do
    frequency = msg |> Extract.frequency()
    state = %{state | vfo_b_frequency: frequency}

    previous_active_frequency = effective_active_frequency(state) || 0
    delta = frequency - previous_active_frequency

    delta = if state.rit_enabled do
      delta + state.rit_xit_offset
    else
      delta
    end

    state =
      if state.active_receiver == :b do
        %{state | active_frequency: frequency, active_frequency_delta: delta}
      else
        %{state | inactive_frequency: frequency}
      end

    state =
      if state.band_scope_mode == :center && state.active_receiver == :b do
        band_scope_edges =
          calculate_center_mode_edges(
            effective_active_frequency(state),
            state.band_scope_span
          )

        %{state | band_scope_edges: band_scope_edges}
      else
        state
      end

    state
  end

  def dispatch(%__MODULE__{} = state, "FL0" <> _ = msg) do
    %{state | active_if_filter: Extract.current_if_filter(msg)}
  end

  def dispatch(%__MODULE__{} = state, "FL1" <> _ = msg) do
    {filter_id, filter_value} = msg |> Extract.roofing_filter()

    roofing_filter_data =
      state.roofing_filter_data
      |> Map.put(filter_id, filter_value)

    %{state | roofing_filter_data: roofing_filter_data}
  end

  def dispatch(%__MODULE__{} = state, "FR0") do
    %{
      state
      | active_receiver: :a,
        active_frequency: state.vfo_a_frequency,
        inactive_receiver: :b,
        inactive_frequency: state.vfo_b_frequency
    }
  end

  def dispatch(%__MODULE__{} = state, "FR1") do
    %{
      state
      | active_receiver: :b,
        active_frequency: state.vfo_b_frequency,
        inactive_receiver: :a,
        inactive_frequency: state.vfo_a_frequency
    }
  end

  # active/operating mode
  def dispatch(%__MODULE__{} = state, "OM0" <> _ = msg) do
    # check whether we're in vfo or memory mode
    # if we're in vfo mode, set active_mode,
    # if we're in memory mode, set memory_channel_active_mode

    mode = Extract.operating_mode(msg)

    case state.vfo_memory_state do
      :vfo ->
        %{state | active_mode: mode}

      :memory ->
        %{state | memory_channel_active_mode: mode}

      _ ->
        state
    end
  end

  # inactive operating mode
  def dispatch(%__MODULE__{} = state, "OM1" <> _ = msg) do
    # check whether we're in vfo or memory moed
    # if we're in vfo mode, set inactive_mode,
    # if we're in memory mode, set memory_channel_inactive_mode
    mode = Extract.operating_mode(msg)

    case state.vfo_memory_state do
      :vfo ->
        %{state | inactive_mode: mode}

      :memory ->
        %{state | memory_channel_inactive_mode: mode}

      other ->
        Logger.warn("Unknown vfo_memory_state: #{inspect(other)}")
        state
    end
  end

  def dispatch(%__MODULE__{} = state, "SH0" <> _ = msg) do
    %{
      ssb_filter_mode: ssb_filter_mode,
      ssb_data_filter_mode: ssb_data_filter_mode,
      filter_state: filter_state
    } = state

    active_mode = effective_active_mode(state)

    filter_mode =
      case active_mode do
        ssb when ssb in [:usb, :lsb] -> ssb_filter_mode
        data when data in [:usb_d, :lsb_d] -> ssb_data_filter_mode
        _ -> nil
      end

    passband_id = Extract.passband_id(msg)

    filter_hi_shift = passband_id |> Extract.filter_hi_shift(filter_mode, active_mode)

    filter_state = %{filter_state | hi_shift: filter_hi_shift, hi_passband_id: passband_id}

    %{state | filter_state: filter_state}
    |> update_filter_hi_edge()
  end

  def dispatch(%__MODULE__{} = state, "SL0" <> _ = msg) do
    %{
      ssb_filter_mode: ssb_filter_mode,
      ssb_data_filter_mode: ssb_data_filter_mode,
      filter_state: filter_state
    } = state

    active_mode = effective_active_mode(state)

    filter_mode =
      case active_mode do
        ssb when ssb in [:usb, :lsb] -> ssb_filter_mode
        data when data in [:usb_d, :lsb_d] -> ssb_data_filter_mode
        _ -> nil
      end

    passband_id = Extract.passband_id(msg)

    filter_lo_width = passband_id |> Extract.filter_lo_width(filter_mode, active_mode)

    filter_state = %{filter_state | lo_width: filter_lo_width, lo_passband_id: passband_id}

    %{state | filter_state: filter_state}
    |> update_filter_lo_edge()
  end

  # dispatch catchall - this needs to be the very last one
  def dispatch(%__MODULE__{} = state, msg) do
    Logger.debug("RadioState.dispatch: unhandled message: #{inspect(msg)}")

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
        offset_freq =
          RadioViewHelpers.offset_frequency(mode, active_frequency, filter_state.hi_shift)

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
        filter_low_freq =
          RadioViewHelpers.offset_frequency_reverse(mode, active_frequency, filter_state.lo_width)

        %{state | filter_low_freq: filter_low_freq}

      _ ->
        state
    end
  end

  def get_active_receiver_frequency(%__MODULE__{
        active_receiver: active_receiver,
        vfo_a_frequency: vfo_a_frequency,
        vfo_b_frequency: vfo_b_frequency
      }) do
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

  def effective_band_edges(%__MODULE__{} = state) do
    case state.band_scope_mode do
      :center -> effective_center_mode_edges(state)
      :fixed -> state.band_scope_fixed_edges
      _ -> state.band_scope_edges
    end
  end

  def effective_center_mode_edges(%__MODULE__{} = state) do
    if state.band_scope_span do
      freq = state |> effective_active_frequency()
      span = state.band_scope_span * 1000

      half_span = span |> div(2)

      bs_low = freq - half_span
      bs_high = freq + half_span

      {bs_low, bs_high}
    else
      nil
    end
  end

  def filter_mode(%__MODULE__{} = radio_state) do
    case effective_active_mode(radio_state) do
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

  # The final frequency that displays on the screen, taking RIT into account
  def effective_active_frequency(%__MODULE__{} = state) do
    base_frequency =
      case state.vfo_memory_state do
        :vfo -> state.active_frequency
        :memory -> state.memory_channel_frequency
        _ -> nil
      end

    if base_frequency do
      if state.rit_enabled && state.rit_xit_offset do
        base_frequency + state.rit_xit_offset
      else
        base_frequency
      end
    else
      0
    end
  end

  def effective_active_mode(%__MODULE__{} = state) do
    case state.vfo_memory_state do
      :vfo ->
        state.active_mode

      :memory ->
        state.memory_channel_active_mode

      other ->
        Logger.warn("Unknown vfo_memory_state: #{inspect(other)}")
        nil
    end
  end

  def effective_inactive_mode(%__MODULE__{} = state) do
    case state.vfo_memory_state do
      :vfo -> state.inactive_mode
      :memory -> state.memory_channel_inactive_mode
      _ -> nil
    end
  end

  # The final frequency display on the right side, taking in split and XIT state into account.
  # This is DIFFERENT from the position that the "T" banner displays on the bandscope.
  def effective_inactive_frequency(%__MODULE__{} = state) do
    base_frequency =
      case state.vfo_memory_state do
        :vfo -> state.inactive_frequency
        :memory -> state.memory_channel_inactive_frequency
        _ -> nil
      end

    if base_frequency do
      if state.split_enabled && state.xit_enabled && state.rit_xit_offset do
        base_frequency + state.rit_xit_offset
      else
        base_frequency
      end
    else
      nil
    end
  end

  def rx_banner_frequency(%__MODULE__{} = state) do
    base_frequency = effective_active_frequency(state)

    if state.tf_set_enabled && state.xit_enabled do
      base_frequency + state.rit_xit_offset
    else
      base_frequency
    end
  end

  def tx_banner_frequency(%__MODULE__{} = state) do
    if state.vfo_memory_state == :memory do
      case effective_inactive_frequency(state) do
        val when is_integer(val) -> val
        nil -> effective_active_frequency(state)
      end
    else
      if state.split_enabled do
        if state.xit_enabled && state.rit_xit_offset do
          state.inactive_frequency + state.rit_xit_offset
        else
          state.inactive_frequency
        end
      else
        if state.xit_enabled && state.rit_xit_offset do
          state.active_frequency + state.rit_xit_offset
        else
          state.active_frequency
        end
      end
    end
  end
end
