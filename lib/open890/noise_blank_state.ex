defmodule Open890.NoiseBlankState do
  defstruct nb_1_enabled: nil, nb_2_enabled: nil

  def any_enabled?(%__MODULE__{} = state) do
    state.nb_1_enabled || state.nb_2_enabled
  end
end
