defmodule Open890.ConnectionCommands do
  require Logger

  alias Open890.RadioConnection
  alias Open890.RadioState

  def get_initial_state(%RadioConnection{} = conn) do
    Logger.debug("*** GET INITIAL STATE ***")

    conn
    |> get_active_receiver()
    |> get_vfo_a_freq()
    |> get_vfo_b_freq()
    |> get_band_register_state()
    |> get_s_meter()
    |> get_filter_modes()
    |> get_vfo_memory_state()
    |> get_modes()
    |> get_filter_state()
    |> get_fine()
    |> get_roofing_filter_info()
    |> get_band_scope_expand()
    |> get_band_scope_mode()
    |> get_band_scope_span()
    # This needs to happen in this spot otherwise stuff breaks
    |> get_band_scope_limits()
    |> get_band_scope_avg()
    |> get_band_scope_att()
    |> get_band_scope_fixed_range_number()
    |> get_busy_led_state()
    |> get_display_screen()
    |> get_rf_pre_att()
    |> get_ref_level()
    |> get_memory_channel_frequencies()
    |> monitor_meters()
    |> get_data_speed()
    |> get_audio_gain()
    |> get_rf_gain()
    |> get_power_level()
    |> get_notch_states()
    |> get_transverter_states()
    |> get_antenna_state()
    |> get_atu_state()
    |> get_cw_key_data()
    |> get_agc()
    |> get_mic_gain()
    |> get_nr()
    |> get_bc()
    |> get_nb_states()
    |> get_squelch()
    |> get_split()
    |> get_apf_state()
    |> get_voip_available()
    |> get_voip_state()
    |> get_rit_xit()
    |> get_lock()
    |> get_mhz()
  end

  def get_busy_led_state(conn), do: conn |> cmd("BY")
  def get_fine(conn), do: conn |> cmd("FS")

  def rit_xit_up(conn), do: conn |> cmd("RU")
  def rit_xit_down(conn), do: conn |> cmd("RD")
  def clear_rit_xit(conn), do: conn |> cmd("RC")

  # def set_rit_xit(conn, value) when is_integer(value) do
  #  direction = if value < 0, do: "1", else: "0"
  #  value = abs(value)
  #          |> to_string()
  #          |> String.pad_leading(4, "0")

  #  conn |> cmd("RF#{direction}#{value}")
  # end

  def get_mhz(conn), do: conn |> cmd("MH")

  def get_lock(conn), do: conn |> cmd("LK")

  def get_rit_xit(conn) do
    conn
    |> cmd("RT")
    |> cmd("XT")
    |> cmd("RF")
  end

  def get_atu_state(conn), do: conn |> cmd("AC")
  def get_voip_available(conn), do: conn |> cmd("##KN2")
  def get_voip_state(conn), do: conn |> cmd("##VP")
  def start_voip(conn), do: conn |> cmd("##VP1")
  def stop_voip(conn), do: conn |> cmd("##VP0")
  def get_apf_state(conn), do: conn |> cmd("AP0")
  def get_split(conn), do: conn |> cmd("TB")

  def get_squelch(conn) do
    conn
    |> cmd("SQ")
  end

  def get_nb_states(conn) do
    conn
    |> cmd("NB1")
    |> cmd("NB2")
  end

  def get_nr(conn), do: conn |> cmd("NR")
  def get_bc(conn), do: conn |> cmd("BC")

  def get_mic_gain(conn) do
    conn |> cmd("MG")
  end

  def get_cw_key_data(conn) do
    conn
    |> cmd("KS")
    |> cmd("SD")
  end

  def get_agc(conn) do
    conn
    |> cmd("GC")
  end

  def get_antenna_state(conn) do
    conn |> cmd("AN")
  end

  def get_band_register_state(conn) do
    conn
    |> cmd("BU0")
    |> cmd("BU1")
  end

  def get_transverter_states(conn) do
    conn |> cmd(["XV", "XO"])
  end

  def get_vfo_memory_state(conn) do
    conn |> cmd("MV")
  end

  def get_memory_channel_frequencies(conn) do
    conn |> cmd(["MA70", "MA71"])
  end

  def get_notch_states(conn) do
    conn
    |> cmd("NT")
    |> cmd("NW")
    |> cmd("BP")
  end

  def set_notch_pos(conn, value) do
    value =
      value
      |> to_string()
      |> String.pad_leading(3, "0")

    conn |> cmd("BP#{value}")
  end

  def get_power_level(conn) do
    conn |> cmd("PC")
  end

  def cw_tune(conn) do
    conn |> cmd("CA1")
  end

  def get_audio_gain(conn) do
    conn |> cmd("AG")
  end

  def get_rf_gain(conn) do
    conn |> cmd("RG")
  end

  def esc(conn), do: conn |> cmd("DS3")
  def ch_up(conn), do: conn |> cmd("CH0")
  def ch_down(conn), do: conn |> cmd("CH1")

  def radio_up(conn, args \\ "03") when is_binary(args) do
    conn |> cmd("UP#{args}")
  end

  def radio_down(conn, args \\ "03") when is_binary(args) do
    conn |> cmd("DN#{args}")
  end

  def monitor_meters(conn) do
    cmds = ~w(RM11 RM21 RM51)
    conn |> cmd(cmds)
  end

  def cw_decode_on(conn) do
    conn |> cmd("CD01")
  end

  def cw_decode_off(conn) do
    conn |> cmd("CD00")
  end

  def freq_change(conn, :up) do
    conn |> cmd("CH0")
  end

  def freq_change(conn, :down) do
    conn |> cmd("CH1")
  end

  def get_ref_level(conn) do
    conn |> cmd("BSC")
  end

  def set_squelch(conn, value) when is_integer(value) do
    value = value |> to_string() |> String.pad_leading(3, "0")
    conn |> cmd("SQ" <> value)
  end

  def set_audio_gain(conn, value) when is_integer(value) do
    value = value |> to_string() |> String.pad_leading(3, "0")
    conn |> cmd("AG" <> value)
  end

  def set_rf_gain(conn, value) when is_integer(value) do
    value = value |> to_string() |> String.pad_leading(3, "0")
    conn |> cmd("RG" <> value)
  end

  def set_ref_level(conn, db_value) when is_float(db_value) do
    cmd_value =
      ((db_value + 20) * 2)
      |> round()
      |> to_string()
      |> String.pad_leading(3, "0")

    conn |> cmd("BSC#{cmd_value}")
  end

  def vfo_a_b_swap(conn) do
    conn |> cmd("EC")
  end

  def get_vfo_a_freq(conn) do
    conn |> cmd("FA")
  end

  def get_vfo_b_freq(conn) do
    conn |> cmd("FB")
  end

  def get_active_receiver(conn) do
    conn |> cmd("FR")
  end

  def get_band_scope_span(conn) do
    conn |> cmd("BS4")
  end

  def get_band_scope_limits(conn) do
    conn |> cmd("BSM0")
  end

  def get_band_scope_fixed_range_number(conn) do
    conn |> cmd("BS5")
  end

  def get_band_scope_mode(conn) do
    conn |> cmd("BS3")
  end

  def get_band_scope_expand(conn) do
    conn |> cmd("BSO")
  end

  def get_s_meter(conn) do
    conn |> cmd("SM")
  end

  def get_display_screen(conn) do
    conn |> cmd("DS1")
  end

  def get_band_scope_att(conn) do
    conn |> cmd("BS8")
  end

  def get_band_scope_avg(conn) do
    conn |> cmd("BSA")
  end

  def get_data_speed(conn) do
    conn |> cmd("DD0")
  end

  def get_roofing_filter_info(conn) do
    cmds = ~w(FL0 FL10 FL11 FL12)
    conn |> cmd(cmds)
  end

  def get_rf_pre_att(conn) do
    conn |> cmd(~w(PA RA))
  end

  def get_modes(conn) do
    get_active_mode(conn)
    get_inactive_mode(conn)
  end

  def get_active_mode(conn) do
    conn |> cmd("OM0")
  end

  def get_inactive_mode(conn) do
    conn |> cmd("OM1")
  end

  def get_filter_state(conn) do
    conn |> cmd(~w(SH0 SL0))
  end

  def get_filter_modes(conn) do
    get_ssb_filter_mode(conn)
    get_ssb_data_filter_mode(conn)
  end

  def get_ssb_filter_mode(conn) do
    conn |> cmd("EX00611")
  end

  def get_ssb_data_filter_mode(conn) do
    conn |> cmd("EX00612")
  end

  def toggle_split(conn, %RadioState{split_enabled: split_enabled}) do
    if split_enabled do
      conn |> cmd("TB0")
    else
      conn |> cmd("TB1")
    end
  end

  def toggle_vfo(conn, %RadioState{active_receiver: active_receiver, split_enabled: split_enabled}) do
    case active_receiver do
      :a ->
        conn |> cmd("FR1")
        if split_enabled, do: conn |> cmd("FT0")

      :b ->
        conn |> cmd("FR0")
        if split_enabled, do: conn |> cmd("FT1")

      _ ->
        conn
    end
  end

  def equalize_vfo(conn) do
    conn |> cmd("VV")
  end

  def band_scope_shift(conn) do
    conn |> cmd("BSE")
  end

  def cmd(conn, cmds) when is_list(cmds) do
    cmds |> Enum.each(fn c -> conn |> cmd(c) end)
    conn
  end

  @doc """
  Send a command to the given Radio Connection
  """
  def cmd(%RadioConnection{} = connection, command) when is_binary(command) do
    connection |> RadioConnection.cmd(command)
  end
end
