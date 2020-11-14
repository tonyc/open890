defmodule Open890.Extract do
  require Logger

  @scope_modes %{
    "0" => :center,
    "1" => :fixed,
    "2" => :auto_scroll
  }

  @ssb_hi_cut_lookup %{
    0 => 600,
    1 => 700,
    2 => 800,
    3 => 900,
    4 => 1000,
    5 => 1100,
    6 => 1200,
    7 => 1300,
    8 => 1400,
    9 => 1500,
    10 => 1600,
    11 => 1700,
    12 => 1800,
    13 => 1900,
    14 => 2000,
    15 => 2100,
    16 => 2200,
    17 => 2300,
    18 => 2400,
    19 => 2500,
    20 => 2600,
    21 => 2700,
    22 => 2800,
    23 => 2900,
    24 => 3000,
    25 => 3400,
    26 => 4000,
    27 => 5000
  }

  @am_hi_cut_lookup %{
    0 => 2000,
    1 => 2100,
    2 => 2200,
    3 => 2300,
    4 => 2400,
    5 => 2500,
    6 => 2600,
    7 => 2700,
    8 => 2800,
    9 => 2900,
    10 => 3000,
    11 => 3500,
    12 => 4000,
    13 => 5000
  }

  @fm_hi_cut_lookup %{
    0 => 1000,
    1 => 1100,
    2 => 1200,
    3 => 1300,
    4 => 1400,
    5 => 1500,
    6 => 1600,
    7 => 1700,
    8 => 1800,
    9 => 1900,
    10 => 2000,
    11 => 2100,
    12 => 2200,
    13 => 2300,
    14 => 2400,
    15 => 2500,
    16 => 2600,
    17 => 2700,
    18 => 2800,
    19 => 2900,
    20 => 3000,
    21 => 3400,
    22 => 4000,
    23 => 5000
  }

  @operating_modes %{
    "0" => :unused,
    "1" => :lsb,
    "2" => :usb,
    "3" => :cw,
    "4" => :fm,
    "5" => :am,
    "6" => :fsk,
    "7" => :cw_r,
    "8" => :unused,
    "9" => :fsk_r,
    "A" => :psk,
    "B" => :psk_r,
    "C" => :lsb_d,
    "D" => :usb_d,
    "E" => :fm_d,
    "F" => :am_d
  }

  def operating_mode(str) when is_binary(str) do
    str
    |> String.trim_leading("OM0")
    |> String.trim_leading("OM1")
    |> case do
      mode -> @operating_modes |> Map.fetch!(mode)
    end
  end

  def scope_mode(str) when is_binary(str) do
    str
    |> String.trim_leading("BS3")
    |> case do
      mode -> @scope_modes |> Map.fetch!(mode)
    end
  end

  # TODO: Convert this to return an integer frequency in Hz
  def frequency(str) when is_binary(str) do
    str
    |> String.trim_leading("FA")
    |> String.trim_leading("FB")
    |> String.trim_leading("0")
  end

  def s_meter(""), do: 0

  def s_meter(str) when is_binary(str) do
    str
    |> String.trim_leading("SM")
    |> String.trim_leading("0")
    |> case do
      "" -> 0
      val -> val |> String.to_integer()
    end
  end

  def band_edges("BSM0" <> low_high) do
    low_high
    |> String.split_at(8)
    |> Tuple.to_list()
  end

  # returns an integer number representing the
  # passband shift/width/hi/lo cut id
  def passband_id(str) when is_binary(str) do
    str
    |> String.trim_leading("SH0")
    |> String.trim_leading("SH1")
    |> String.trim_leading("SL0")
    |> String.trim_leading("SL1")
    |> String.to_integer()
  end

  # returns hi_lo_cut or :shift_width based on the filter mode for menu EX 0 06 11/12
  def filter_mode(str) when is_binary(str) do
    str
    |> String.trim_leading("EX006")
    |> String.trim_leading("11")
    |> String.trim_leading("12")
    |> String.trim_leading(" 00")
    |> case do
      "0" -> :hi_lo_cut
      "1" -> :shift_width
    end
  end

  def filter_hi_shift(passband_id, filter_mode, current_mode) do
    case filter_mode do
      :hi_lo_cut ->
        cond do
          [:usb, :usb_d, :lsb, :lsb_d] |> Enum.member?(current_mode) ->
            @ssb_hi_cut_lookup |> Map.fetch!(passband_id)

          # this doesn't belong here
          [:cw, :cw_r] |> Enum.member?(current_mode) ->
            passband_id |> calculate_cw_shift()

          [:am, :am_d] |> Enum.member?(current_mode) ->
            @am_hi_cut_lookup |> Map.fetch!(passband_id)

          [:fm, :fm_d] |> Enum.member?(current_mode) ->
            @fm_hi_cut_lookup |> Map.fetch!(passband_id)

          true ->
            Logger.warn("Unknown mode for high/shift: #{inspect(current_mode)}")
            -1
        end

      :shift_width ->
        cond do
          [:usb, :usb_d, :lsb, :lsb_d] |> Enum.member?(current_mode) ->
            passband_id |> calculate_ssb_shift()

          [:cw, :cw_r] |> Enum.member?(current_mode) ->
            passband_id |> calculate_cw_shift()

          true ->
            Logger.warn("Unknown mode for hi_shift: :shift_width: #{inspect(current_mode)}")
            -1
        end
    end
  end

  defp calculate_cw_shift(passband_id)
       when is_integer(passband_id) and passband_id >= 0 and passband_id <= 160 do
    10 * passband_id - 800
  end

  defp calculate_ssb_shift(passband_id)
       when is_integer(passband_id) and passband_id >= 0 and passband_id <= 49 do
    50 * passband_id + 50
  end
end
