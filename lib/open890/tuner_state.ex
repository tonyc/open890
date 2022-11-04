defmodule Open890.TunerState do
  defstruct rx_enabled: false, tx_enabled: false, tuning_active: false

  def toggle_tuner_state(%__MODULE__{tx_enabled: tx_enabled} = mod) do
    if tx_enabled do
      mod |> disable_tuner()
    else
      mod |> enable_tuner()
    end
  end

  def disable_tuner(%__MODULE__{} = state) do
    %{state | tx_enabled: false}
  end

  def enable_tuner(%__MODULE__{} = state) do
    %{state | tx_enabled: true}
  end

  def to_command(%__MODULE__{} = state) do
    p2 = state.tx_enabled |> boolean_to_str()
    p3 = state.tuning_active |> boolean_to_str()

    ["AC", "1", p2, p3] |> Enum.join()

  end

  defp boolean_to_str(true), do: "1"
  defp boolean_to_str(false), do: "0"
end
