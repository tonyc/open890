defmodule Open890.FilterState do
  defstruct lo_width: nil, hi_shift: nil, lo_passband_id: nil, hi_passband_id: nil

  # this can change depending on the current mode, and the filter lo/width hi/cut mode config for the radio
  def width(%__MODULE__{lo_width: lo_width}) do
    lo_width
  end

  def hi_cut(%__MODULE__{hi_shift: hi_shift}) do
    hi_shift
  end
end
