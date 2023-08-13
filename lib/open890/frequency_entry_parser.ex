defmodule Open890.FrequencyEntryParser do
  def parse(str) when is_binary(str) do
    # first digit 0-5 will land in the "tens" mhz
    # anything else will start in the "ones" mhz field

    # if FINE is on, go out to the last digit, otherwise go to the second to last

    # FIXME: if the transverter is on, assume the first digit is ghz

    # FB 00 014 080 440


    str
    |> String.replace(~r/[^\.0-9]/, "")
    |> String.split(".")
    |> case do
      [str] when is_binary(str) ->
        str
        |> String.graphemes()
        |> to_integers()
        |> pad_unparsed_digits()

      ["" = _mhz | [khz] = _rest] ->
        pad_mhz_khz("0", khz)

      [mhz | [khz]] ->
        pad_mhz_khz(mhz, khz)
    end
  end

  defp pad_mhz_khz(mhz, khz) do
    mhz_padded = mhz
    |> String.slice(0, 5)
    |> String.pad_leading(5, "0")

    rest_padded = khz
    |> String.pad_trailing(6, "0")
    |> String.slice(0, 6)

    mhz_padded <> rest_padded
  end

  defp pad_unparsed_digits(digits) when is_list(digits) do
    first_digit = Enum.at(digits, 0)

    len = if first_digit <= 5, do: 8, else: 7

    digits
    |> Enum.join("")
    |> String.slice(0, len)
    |> String.pad_trailing(len, "0")
    |> String.pad_leading(11, "0")
  end

  defp to_integers(l) when is_list(l) do
    Enum.map(l, fn x ->
      {digit, _remainder} = Integer.parse(x)
      digit
    end)
  end
end
