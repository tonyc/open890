defmodule Open890.ConnectionCommands do
  require Logger

  alias Open890.RadioConnection

  def get_initial_state(%RadioConnection{} = conn) do
    conn |> get_active_receiver()
    conn |> get_vfo_a_freq()
    conn |> get_vfo_b_freq()
    conn |> get_s_meter()
    conn |> get_modes()
    conn |> get_filter_modes()
    conn |> get_filter_state()
    conn |> get_band_scope_limits()
    conn |> get_band_scope_mode()
    conn |> get_band_scope_att()
    conn |> get_display_screen()
    conn |> get_rf_pre_att()
    conn |> get_ref_level()
    conn |> monitor_meters()
  end

  def cw_tune(conn) do
    conn |> cmd("CA1")
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
    cmds = ~w(RM11 RM21)
    conn |> run_commands(cmds)
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

  def get_band_scope_limits(conn) do
    conn |> cmd("BSM0")
  end

  def get_band_scope_mode(conn) do
    conn |> cmd("BS3")
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

  def get_roofing_filter_info(conn) do
    cmds = ~w(FL0 FL10 FL11 FL12)
    conn |> run_commands(cmds)
  end

  def get_rf_pre_att(conn) do
    cmds = ~w(PA RA)
    conn |> run_commands(cmds)
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
    cmds = ~w(SH0 SL0)

    conn |> run_commands(cmds)
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

  defp run_commands(conn, cmds) when is_list(cmds) do
    cmds
    |> Enum.each(fn c ->
      conn |> cmd(c)
    end)
  end

  @doc """
  Send a command to the given Radio Connection
  """
  def cmd(%RadioConnection{} = connection, command) when is_binary(command) do
    connection |> RadioConnection.cmd(command)
  end
end
