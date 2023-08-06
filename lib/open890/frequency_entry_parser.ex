defmodule Open890.FrequencyEntryParser do
  def parse(str) when is_binary(str) do
    # first digit 0-5 will land in the "tens" mhz
    # anything else will start in the "ones" mhz field

    # if FINE is on, go out to the last digit, otherwise go to the second to last

    # FIXME: if the transverter is on, assume the first digit is ghz

    # FB 00 014 080 440


    digits = str
    |> String.replace(~r/[^0-9]/, "")
    |> String.graphemes()
    |> Enum.map(fn x ->
      case Integer.parse(x) do
        {digit, _remainder} -> digit
      end
    end)

    first_digit = Enum.at(digits, 0)

    len = if first_digit <= 5, do: 8, else: 7

    digits
    |> Enum.join("")
    |> String.slice(0, len)
    |> String.pad_trailing(len, "0")
    |> String.pad_leading(11, "0")
  end
end
