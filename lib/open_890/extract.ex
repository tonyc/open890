defmodule Open890.Extract do
  @scope_modes %{
    "0" => :center,
    "1" => :fixed,
    "2" => :auto_scroll
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
    |> String.trim_leading("SH")
    |> String.trim_leading("SL")
    |> String.trim_leading("0")
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

end
