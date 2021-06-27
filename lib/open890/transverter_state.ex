defmodule Open890.TransverterState do
  defstruct enabled: false, offset: 0

  def apply_offset(%__MODULE__{} = state, freq) when is_integer(freq) do
    if state.enabled do
      freq + state.offset
    else
      freq
    end
  end
end
