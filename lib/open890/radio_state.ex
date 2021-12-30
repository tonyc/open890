defmodule Open890.RadioState do
  alias Open890.{AntennaState, BandRegisterState, FilterState, NoiseBlankState, NotchState, TransverterState}

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
  ]

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
end
