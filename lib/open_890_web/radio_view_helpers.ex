defmodule Open890Web.RadioViewHelpers do
  import Phoenix.HTML.Tag

  def selected_theme?(theme, name) do
    if theme == name, do: "selected"
  end

  def cmd_button(name, cmd, opts \\ []) when is_binary(name) and is_binary(cmd) do
    content_tag(:button, name, opts |> Keyword.merge(phx_click: "cmd", phx_value_cmd: cmd))
  end

  def format_band_scope_mode(mode) do
    mode
    |> case do
      :auto_scroll -> "Auto Scroll"
      :fixed -> "Fixed"
      :center -> "Center"
    end
  end

  def project_to_limits(frequency, low, high) do
    low = low |> String.to_integer()
    high = high |> String.to_integer()
    frequency = frequency |> String.to_integer()

    delta = high - low

    freq_delta = frequency - low

    percentage = freq_delta / delta

    percentage * 640
  end

  # formats a raw frequency in Hz to e.g.
  # 7.055.123
  def format_raw_frequency(str) do
    str
    |> to_string()
    |> String.trim_leading("0")
    |> String.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3, 3, [])
    |> Enum.join(".")
    |> String.reverse()
  end

  def s_meter_value_to_s_units(val) when is_integer(val) do
    cond do
      val >= 70 -> "S9+60"
      val >= 58 -> "S9+40"
      val >= 47 -> "S9+20"
      val >= 35 -> "S9"
      val >= 27 -> "S7"
      val >= 19 -> "S5"
      val >= 11 -> "S3"
      val >= 3 -> "S1"
      true -> "S0"
    end
  end

  def format_mode(mode) when is_atom(mode) or is_binary(mode) do
    mode
    |> to_string()
    |> String.replace("_", "-")
    |> String.upcase()
  end
end
