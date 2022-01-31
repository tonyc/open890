defmodule Open890.AntennaState do
  # AN - antenna selection
  # P1: 0: ANT1, 1: ANT2
  # P2: 0: RX ANT off, 1: RX ANT on
  # P3: 0: DRV off, 1: DRV on
  # P4: 0: ANT OUT off, 1: ANT OUT on
  defstruct active_ant: nil, rx_ant_enabled: false, drv_enabled: false, ant_out_enabled: false

  def extract(str) when is_binary(str) do
    str = str |> String.trim_leading("AN")

    active_ant =
      String.at(str, 0)
      |> case do
        "1" -> :ant1
        "2" -> :ant2
        _ -> nil
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
end
