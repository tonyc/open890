defmodule Open890.MemoryChannel do
  alias Open890.{Extract}

  defstruct channel_number: nil,
    frequency: nil,
    mode: :unknown,
    fm_narrow_mode: :normal,
    fm_tone_type: nil,
    tone_freq: nil,
    ctcss_freq: nil,
    split_freq: "",
    split_mode: nil,
    split_fm_narrow_mode: nil,
    split_info: 0,
    scan_lockout: :off,
    channel_name: ""

  def extract(str) when is_binary(str) do
    <<
      channel_number::binary-size(3),
      freq::binary-size(11),
      mode::binary-size(1),
      fm_narrow::binary-size(1),
      fm_tone_type::binary-size(1),
      _tone_freq::binary-size(2),
      _ctcss_freq::binary-size(2),
      split_freq::binary-size(11),
      split_mode::binary-size(1),
      split_fm_narrow_mode::binary-size(1),
      split_info::binary-size(1),
      scan_lockout::binary-size(1),
      channel_name::binary
    >> = str
         |> String.trim_leading("MA0")
         |> String.trim_trailing(";")


    %__MODULE__{
      channel_number: channel_number,
      frequency: freq |> parse_frequency(),
      mode: mode |> Extract.operating_mode(),
      fm_narrow_mode: fm_narrow |> parse_fm_narrow_mode(),
      fm_tone_type: fm_tone_type |> parse_fm_tone_type(),
      #tone_freq: tone_freq |> parse_tone_freq(),
      #ctcss_freq: ctcss_freq |> parse_ctcss_freq(),
      split_freq: split_freq |> parse_frequency(),
      split_mode: split_mode |> Extract.operating_mode(),
      split_fm_narrow_mode: split_fm_narrow_mode |> parse_fm_narrow_mode(),
      split_info: split_info |> parse_split_info(),
      scan_lockout: scan_lockout |> parse_scan_lockout(),
      channel_name: channel_name |> parse_channel_name(),
    }
  end

  def parse_channel_name(str) when is_binary(str) do
    str |> String.trim()
  end

  def parse_scan_lockout(str) when is_binary(str) do
    str
    |> case do
      "1" -> :on
      _ -> :off
    end
  end

  def parse_split_info(str) when is_binary(str) do
    str
    |> case do
      "1" -> :split
      _ -> :simplex
    end
  end

  def parse_tone_freq(str) when is_binary(str) do
  end

  def parse_fm_tone_type(str) when is_binary(str) do
    str
    |> case do
      "1" -> :tone
      "2" -> :ctcss
      "3" -> :cross_tone
      _ -> :off
    end
  end

  def parse_fm_narrow_mode(str) when is_binary(str) do
    str
    |> case do
      "1" -> :narrow
      _ -> :normal
    end
  end

  def parse_frequency(str) when is_binary(str) do
    str
    |> String.trim_trailing(" ")
    |> case do
      "" -> nil
      other -> other |> String.to_integer()
    end

  end

end
