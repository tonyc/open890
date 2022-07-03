defmodule Open890.AntennaState do
  # AN - antenna selection
  # P1: 1: ANT1, 2: ANT2
  # P2: 0: RX ANT off, 1: RX ANT on
  # P3: 0: DRV off, 1: DRV on
  # P4: 0: ANT OUT off, 1: ANT OUT on
  defstruct active_ant: :ant1, rx_ant_enabled: false, drv_enabled: false, ant_out_enabled: false

  def extract(str) when is_binary(str) do
    str = str |> String.trim_leading("AN")

    active_ant =
      String.at(str, 0)
      |> case do
        "2" -> :ant2
        _ -> :ant1
      end

    rx_ant_enabled = String.at(str, 1) == "1"
    drv_enabled = String.at(str, 2) == "1"
    ant_out_enabled = String.at(str, 3) == "1"

    %__MODULE__{
      active_ant: active_ant,
      rx_ant_enabled: rx_ant_enabled,
      drv_enabled: drv_enabled,
      ant_out_enabled: ant_out_enabled
    }
  end

  def extract(_), do: %__MODULE__{}

  def to_command(%__MODULE__{} = state) do
    p1 = case state.active_ant do
      :ant1 -> "1"
      _ -> "2"
    end

    p2 = state.rx_ant_enabled |> boolean_to_str()
    p3 = state.drv_enabled |> boolean_to_str()
    p4 = state.ant_out_enabled |> boolean_to_str()

    ["AN", p1, p2, p3, p4] |> Enum.join("")
  end

  def toggle_ant(%__MODULE__{active_ant: active_ant} = mod) do
    case active_ant do
      :ant1 ->
        mod |> enable_ant_2()
        _ -> mod |> enable_ant_1()
    end
  end

  def enable_ant_1(%__MODULE__{} = mod) do
    %{mod | active_ant: :ant1}
  end

  def enable_ant_2(%__MODULE__{} = mod) do
    %{mod | active_ant: :ant_2}
  end

  def toggle_rx_ant(%__MODULE__{rx_ant_enabled: enabled} = mod) do
    if enabled do
      mod |> disable_rx_ant()
    else
      mod |> enable_rx_ant()
    end
  end

  def enable_rx_ant(%__MODULE__{} = mod) do
    %{mod | rx_ant_enabled: true}
  end

  def disable_rx_ant(%__MODULE__{} = mod) do
    %{mod | rx_ant_enabled: false}
  end

  def toggle_drv(%__MODULE__{drv_enabled: enabled} = mod) do
    if enabled do
      mod |> disable_drv()
    else
      mod |> enable_drv()
    end
  end
  def enable_drv(%__MODULE__{} = mod) do
    %{mod | drv_enabled: true}
  end

  def disable_drv(%__MODULE__{} = mod) do
    %{mod | drv_enabled: false}
  end

  def toggle_ant_out(%__MODULE__{ant_out_enabled: enabled} = mod) do
    if enabled do
      mod |> disable_ant_out()
    else
      mod |> enable_ant_out()
    end
  end

  def enable_ant_out(%__MODULE__{} = mod) do
    %{mod | ant_out_enabled: true}
  end

  def disable_ant_out(%__MODULE__{} = mod) do
    %{mod | ant_out_enabled: false}
  end

  defp boolean_to_str(true), do: "1"
  defp boolean_to_str(false), do: "0"
end
