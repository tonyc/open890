defmodule Open890.Extract do
  require Logger

  @scope_modes %{
    "0" => :center,
    "1" => :fixed,
    "2" => :auto_scroll
  }

  @ssb_lo_cut_lookup {
    0, 50, 100, 200, 300,
    400, 500, 600, 700, 800,
    900, 1000, 1100, 1200, 1300,
    1400, 1500, 1600, 1700, 1800,
    1900, 2000
  }

  @am_lo_cut_lookup { 0, 100, 200, 300 }

  @fm_lo_cut_lookup {
    0, 50, 100, 200, 300,
    400, 500, 600, 700, 800,
    900, 1000
  }

  @ssb_width_lookup {
    50, 80, 100, 150, 200,
    250, 300, 350, 400, 450,
    500, 600, 700, 900, 1000,
    1100, 1200, 1300, 1400, 1500,
    1600, 1700, 1800, 1900, 2000,
    2100, 2200, 2300, 2400, 2500,
    2600, 2700, 2800, 2900, 3000
  }

  @cw_width_lookup {
    50, 80, 100, 150, 200,
    250, 300, 350, 400, 450,
    500, 600, 700, 800, 900,
    1000, 1500, 2000, 2500
  }

  @fsk_width_lookup { 250, 300, 350, 400, 450, 500, 1000, 1500 }

  @psk_width_lookup {
    50, 80, 100, 150, 200,
    250, 300, 350, 450, 500,
    600, 700, 800, 900, 1000,
    1200, 1400, 1500, 1600, 1800,
    2000, 2200, 2400, 2600, 2800,
    3000
  }

  @ssb_hi_cut_lookup {
    600, 700, 800, 900, 1000,
    1100, 1200, 1300, 1400, 1500,
    1600, 1700, 1800, 1900, 2000,
    2100, 2200, 2300, 2400, 2500,
    2600, 2700, 2800, 2900, 3000,
    3400, 4000, 5000
  }

  @am_hi_cut_lookup {
    2000, 2100, 2200, 2300, 2400,
    2500, 2600, 2700, 2800, 2900,
    3000, 3500, 4000, 5000
  }

  @fm_hi_cut_lookup {
    1000, 1100, 1200, 1300, 1400,
    1500, 1600, 1700, 1800, 1900,
    2000, 2100, 2200, 2300, 2400,
    2500, 2600, 2700, 2800, 2900,
    3000, 3400, 4000, 5000
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

  def filter_lo_width(passband_id, :hi_lo_cut, current_mode) do
    cond do
      current_mode in [:usb, :usb_d, :lsb, :lsb_d] ->
        @ssb_lo_cut_lookup |> elem(passband_id)

      current_mode in [:am, :am_d] ->
        @am_lo_cut_lookup |> elem(passband_id)

      current_mode in [:fm, :fm_d] ->
        @fm_lo_cut_lookup |> elem(passband_id)

      true ->
        Logger.warn("Unknown mode for lo/width: #{inspect(current_mode)}")
        -1
    end

  end

  def filter_lo_width(passband_id, :shift_width, current_mode) do

  end

  def filter_hi_shift(passband_id, _filter_mode, :cw) do
    passband_id |> calculate_cw_shift()
  end

  def filter_hi_shift(passband_id, _filter_mode, :cw_r) do
    passband_id |> calculate_cw_shift()
  end

  def filter_hi_shift(passband_id, filter_mode, current_mode) do
    case filter_mode do

      :hi_lo_cut ->
        cond do
          current_mode in [:usb, :usb_d, :lsb, :lsb_d] ->
            @ssb_hi_cut_lookup |> elem(passband_id)

          current_mode in [:am, :am_d] ->
            @am_hi_cut_lookup |> elem(passband_id)

          current_mode in [:fm, :fm_d] ->
            @fm_hi_cut_lookup |> elem(passband_id)

          true ->
            Logger.warn("Unknown mode for high/shift: #{inspect(current_mode)}")
            -1
        end

      :shift_width ->
        cond do
          current_mode in [:usb, :usb_d, :lsb, :lsb_d] ->
            passband_id |> calculate_ssb_shift()

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
