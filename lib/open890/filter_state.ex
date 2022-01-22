defmodule Open890.FilterState do
  defstruct lo_width: nil, hi_shift: nil, lo_passband_id: nil, hi_passband_id: nil

  def width(%__MODULE__{lo_width: lo_width}) do
    lo_width
  end
end
