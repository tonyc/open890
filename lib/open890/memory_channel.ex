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
    scan_lockout: 0,
    channel_name: ""

  def extract(str) when is_binary(str) do
    <<
      channel_number::binary-size(3),
      freq::binary-size(11),
      _rest::binary
      #mode::binary-size(1),
      #fm_info::binary-size(1),
      #fm_tone_type::binary-size(1),
      #tone_freq::binary-size(1),
      #ctcss_freq::binary-size(1),
      #split_freq::binary-size(11),
      #split_mode::binary-size(1),
      #split_fm_narrow_mode::binary-size(1),
      #split_info::binary-size(1),
      #scan_lockout::binary-size(1),
      #channel_name::binary-size(10),
    >> = str
         |> String.trim_leading("MA0")
         |> String.trim_trailing(";")

    frequency = freq
                |> String.trim_trailing(" ")
                |> case do
                  "" -> nil
                  other -> other |> String.to_integer()
                end

    %__MODULE__{
      channel_number: channel_number,
      frequency: frequency
    }
  end

end
