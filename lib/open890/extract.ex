defmodule Open890.Extract do
  require Logger

  alias Open890.AntennaState

  @scope_modes %{
    "0" => :center,
    "1" => :fixed,
    "2" => :auto_scroll
  }

  @ssb_lo_cut_lookup {
    0,
    50,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    1000,
    1100,
    1200,
    1300,
    1400,
    1500,
    1600,
    1700,
    1800,
    1900,
    2000
  }

  @ssb_width_lookup {
    50,
    80,
    100,
    150,
    200,
    250,
    300,
    350,
    400,
    450,
    500,
    600,
    700,
    800,
    900,
    1000,
    1100,
    1200,
    1300,
    1400,
    1500,
    1600,
    1700,
    1800,
    1900,
    2000,
    2100,
    2200,
    2300,
    2400,
    2500,
    2600,
    2700,
    2800,
    2900,
    3000
  }

  @am_lo_cut_lookup {0, 100, 200, 300}

  @fm_lo_cut_lookup {
    0,
    50,
    100,
    200,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
    1000
  }

  @cw_width_lookup {
    50,
    80,
    100,
    150,
    200,
    250,
    300,
    350,
    400,
    450,
    500,
    600,
    700,
    800,
    900,
    1000,
    1500,
    2000,
    2500
  }

  @fsk_width_lookup {250, 300, 350, 400, 450, 500, 1000, 1500}

  @psk_width_lookup {
    50,
    80,
    100,
    150,
    200,
    250,
    300,
    350,
    450,
    500,
    600,
    700,
    800,
    900,
    1000,
    1200,
    1400,
    1500,
    1600,
    1800,
    2000,
    2200,
    2400,
    2600,
    2800,
    3000
  }

  @ssb_hi_cut_lookup {
    600,
    700,
    800,
    900,
    1000,
    1100,
    1200,
    1300,
    1400,
    1500,
    1600,
    1700,
    1800,
    1900,
    2000,
    2100,
    2200,
    2300,
    2400,
    2500,
    2600,
    2700,
    2800,
    2900,
    3000,
    3400,
    4000,
    5000
  }

  @am_hi_cut_lookup {
    2000,
    2100,
    2200,
    2300,
    2400,
    2500,
    2600,
    2700,
    2800,
    2900,
    3000,
    3500,
    4000,
    5000
  }

  @fm_hi_cut_lookup {
    1000,
    1100,
    1200,
    1300,
    1400,
    1500,
    1600,
    1700,
    1800,
    1900,
    2000,
    2100,
    2200,
    2300,
    2400,
    2500,
    2600,
    2700,
    2800,
    2900,
    3000,
    3400,
    4000,
    5000
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

  def split_enabled(str) when is_binary(str) do
    str |> String.trim_leading("TB") == "1"
  end

  def agc(str) when is_binary(str) do
    str
    |> String.trim_leading("GC")
    |> case do
      "0" -> :off
      "1" -> :slow
      "2" -> :med
      "3" -> :fast
      _ -> :unknown
    end
  end

  def bc(str) when is_binary(str) do
    str
    |> String.trim_leading("BC")
    |> case do
      "0" -> :off
      "1" -> :bc_1
      "2" -> :bc_2
    end
  end

  def band_register(str) when is_binary(str) do
    str |> trim_to_integer(["BU0", "BU1"])
  end

  def transverter_enabled(str) when is_binary(str) do
    str
    |> String.trim_leading("XV")
    |> case do
      "1" -> true
      _ -> false
    end
  end

  def transverter_offset(str) when is_binary(str) do
    str
    |> String.trim_leading("XO")
    |> case do
      "0" <> offset ->
        offset |> String.to_integer()
      "1" <> offset ->
        -(String.to_integer(offset))
    end
  end

  def nr(str) when is_binary(str) do
    str
    |> trim_to_integer(["NR"])
    |> case do
      0 -> :off
      1 -> :nr_1
      2 -> :nr_2
    end
  end

  def nb_enabled(str) when is_binary(str) do
    str
    |> trim_to_integer(["NB1", "NB2"])
    |> case do
      1 -> true
      _ -> false
    end
  end

  def mic_gain(str) when is_binary(str) do
    str |> trim_to_integer(["MG0"])
  end

  def notch_filter(str) when is_binary(str) do
    str |> trim_to_integer(["BP"])
  end

  def notch_state(str) when is_binary(str) do
    str
    |> String.trim_leading("NT")
    |> case do
      "1" -> true
      _ -> false
    end
  end

  def notch_width(str) when is_binary(str) do
    str
    |> String.trim_leading("NW")
    |> case do
      "0" -> :narrow
      "1" -> :mid
      "2" -> :wide
    end
  end

  def vfo_memory_state(str) when is_binary(str) do
    str
    |> String.trim_leading("MV")
    |> case do
      "0" -> :vfo
      _ -> :memory
    end
  end

  def power_level(str) when is_binary(str) do
    str |> trim_to_integer(["PC"])
  end

  def key_speed(str) when is_binary(str) do
    str |> trim_to_integer(["KS"])
  end

  def cw_delay(str) when is_binary(str) do
    delay_ms = str
    |> trim_to_integer(["SD"])

    div(delay_ms, 50)
  end

  def audio_gain(str) when is_binary(str) do
    str |> trim_to_integer(["AG"])
  end

  def rf_gain(str) when is_binary(str) do
    str |> trim_to_integer(["RG"])
  end

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
    str |> trim_to_integer(["FA", "FB", "0"])
  end

  def alc_meter(str) when is_binary(str) do
    str |> trim_to_integer(["RM1"])
  end

  def swr_meter(str) when is_binary(str) do
    str |> trim_to_integer(["RM2"])
  end

  def comp_meter(str) when is_binary(str) do
    str |> trim_to_integer(["RM3"])
  end

  def id_meter(str) when is_binary(str) do
    str |> trim_to_integer(["RM4"])
  end

  def vd_meter(str) when is_binary(str) do
    str |> trim_to_integer(["RM5"])
  end

  def temp_meter(str) when is_binary(str) do
    str |> trim_to_integer(["RM6"])
  end

  def s_meter(""), do: 0

  def s_meter(str) when is_binary(str) do
    str
    |> trim_all_leading(["SM", "0"])
    |> case do
      "" -> 0
      val -> val |> String.to_integer()
    end
  end

  def ref_level(str) when is_binary(str) do
    str
    |> trim_to_integer(["BSC0"])
  end

  def band_edges("BSM0" <> low_high) do
    low_high
    |> String.split_at(8)
    |> Tuple.to_list()
    |> Enum.map(&String.to_integer/1)
  end

  # returns an integer number representing the
  # passband shift/width/hi/lo cut id
  def passband_id(str) when is_binary(str) do
    str
    |> trim_to_integer(["SH0", "SH1", "SL0", "SL1"])
  end

  def current_if_filter(str) when is_binary(str) do
    str
    |> String.trim_leading("FL0")
    |> String.first()
    |> case do
      "0" -> :a
      "1" -> :b
      _ -> :c
    end
  end

  # Returns e.g. {:roofing_filter_a, filter_width_in_hz}
  def roofing_filter(str) when is_binary(str) do
    # FL1 0 00050

    raw_val = str |> String.trim_leading("FL1")

    filter_id =
      raw_val
      |> String.first()
      |> case do
        "0" -> :a
        "1" -> :b
        "2" -> :c
      end

    filter_value =
      str
      |> String.slice(-4..-1)
      |> Integer.parse()
      |> elem(0)
      |> Kernel.*(10)

    {filter_id, filter_value}
  end

  # returns hi_lo_cut or :shift_width based on the filter mode for menu EX 0 06 11/12
  def filter_mode(str) when is_binary(str) do
    str
    |> trim_all_leading(["EX006", "11", "12", " 00"])
    |> case do
      "0" -> :hi_lo_cut
      "1" -> :shift_width
    end
  end

  def filter_lo_width(passband_id, _ssb_filter_mode, mode) when mode in [:cw, :cw_r] do
    @cw_width_lookup |> elem(passband_id)
  end

  def filter_lo_width(passband_id, _ssb_filter_mode, mode) when mode in [:fsk, :fsk_r] do
    @fsk_width_lookup |> elem(passband_id)
  end

  def filter_lo_width(passband_id, _ssb_filter_mode, mode) when mode in [:psk, :psk_r] do
    @psk_width_lookup |> elem(passband_id)
  end

  def filter_lo_width(passband_id, _ssb_filter_mode, mode) when mode in [:am, :am_d] do
    @am_lo_cut_lookup |> elem(passband_id)
  end

  def filter_lo_width(passband_id, _ssb_filter_mode, mode) when mode in [:fm, :fm_d] do
    @fm_lo_cut_lookup |> elem(passband_id)
  end

  def filter_lo_width(passband_id, filter_mode, mode) when mode in [:usb, :usb_d, :lsb, :lsb_d] do
    case filter_mode do
      :hi_lo_cut ->
        @ssb_lo_cut_lookup |> elem(passband_id)

      :shift_width ->
        @ssb_width_lookup |> elem(passband_id)
    end
  end

  # def filter_lo_width(passband_id, filter_mode, mode) when mode in [:usb_d, :lsb_d] do
  #   Logger.warn("Unimplemented filter_lo_width for mode:#{inspect(mode)}, filter_mode:#{inspect(filter_mode)}, passband_id:#{inspect(passband_id)}")
  #   nil
  # end

  def filter_lo_width(passband_id, filter_mode, mode) do
    Logger.warn(
      "Unknown passband_id, filter_mode, mode: #{inspect({passband_id, filter_mode, mode})}"
    )
    nil
  end

  def filter_hi_shift(passband_id, _filter_mode, :cw) do
    passband_id |> calculate_cw_shift()
  end

  def filter_hi_shift(passband_id, _filter_mode, :cw_r) do
    passband_id |> calculate_cw_shift()
  end

  def filter_hi_shift(passband_id, _filter_mode, mode) when mode in [:am, :am_d] do
    @am_hi_cut_lookup |> elem(passband_id)
  end

  def filter_hi_shift(passband_id, _filter_mode, mode) when mode in [:fm, :fm_d] do
    @fm_hi_cut_lookup |> elem(passband_id)
  end

  def filter_hi_shift(passband_id, filter_mode, current_mode) do
    {passband_id, filter_mode, current_mode} |> IO.inspect(label: "*** filter_hi_shift")
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
            nil
        end

      :shift_width ->
        cond do
          current_mode in [:usb, :usb_d, :lsb, :lsb_d] ->
            passband_id |> calculate_ssb_shift()

          current_mode in [:usb_d, :lsb_d] ->
            Logger.debug("Unimplemented filter_hi_shift for mode: #{current_mode}, filter_mode:#{inspect(filter_mode)}, passband_id:#{inspect(passband_id)}")
            nil

          true ->
            Logger.debug("Unknown mode for hi_shift: :shift_width: #{inspect(current_mode)}")
            nil
        end

        _ ->
          Logger.debug("Unknown filter mode #{filter_mode} for #{current_mode}")
    end
  end

  def display_screen_id(str) when is_binary(str) do
    str |> trim_to_integer("DS1")
  end

  def rf_att(str) when is_binary(str) do
    str |> trim_to_integer("RA")
  end

  def rf_pre(str) when is_binary(str) do
    str |> trim_to_integer("PA")
  end

  def sql(str) when is_binary(str) do
    str |> trim_to_integer("SQ")
  end

  def band_scope_avg(str) when is_binary(str) do
    str |> trim_to_integer("BSA")
  end

  def band_scope_att(str) when is_binary(str) do
    str |> trim_to_integer("BS8")
  end

  def band_scope_span(str) when is_binary(str) do
    str
    |> trim_to_integer("BS4")
    |> case do
      0 -> 5
      1 -> 10
      2 -> 20
      3 -> 30
      4 -> 50
      5 -> 100
      6 -> 200
      7 -> 500
    end
  end

  def delay_msec(str) when is_binary(str) do
    delay = str |> trim_to_integer("DE")

    delay = max(min(delay, 255), 0)

    delay_ms = delay * 10

    delay_ms
  end

  def data_speed(str) when is_binary(str) do
    str |> trim_to_integer("DD0")
  end

  def antenna_state(str) when is_binary(str) do
    AntennaState.extract(str)
  end

  defp calculate_cw_shift(passband_id)
       when is_integer(passband_id) and passband_id >= 0 and passband_id <= 160 do
    10 * passband_id - 800
  end

  defp calculate_ssb_shift(passband_id)
       when is_integer(passband_id) and passband_id >= 0 and passband_id <= 49 do
    50 * passband_id + 50
  end

  def trim_to_integer(src, leading_str) when is_binary(src) and is_binary(leading_str) do
    src
    |> String.trim_leading(leading_str)
    |> String.to_integer()
  end

  def trim_to_integer(src, items) when is_binary(src) and is_list(items) do
    src
    |> trim_all_leading(items)
    |> String.to_integer()
  end

  def trim_all_leading(src, items) when is_binary(src) and is_list(items) do
    items
    |> Enum.reduce(src, &String.trim_leading(&2, &1))
  end
end
