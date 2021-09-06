defmodule Open890.BandRegisterState do
  defstruct vfo_a_band: nil, vfo_b_band: nil

  def band_for(%__MODULE__{} = m, :a) do
    m.vfo_a_band
  end

  def band_for(%__MODULE__{} = m, :b) do
    m.vfo_b_band
  end

  def band_for(_, _), do: ""
end
