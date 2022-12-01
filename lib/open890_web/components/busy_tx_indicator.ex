defmodule Open890Web.Components.BusyTxIndicator do
  use Phoenix.Component

  def busy_tx(assigns) do
    ~H"""
      <div class={class_for_state(assigns)}></div>
    """
  end

  def class_for_state(assigns \\ %{}) do
    led_state =
      if assigns[:tx_state] != :off do
        :tx
      else
        case assigns[:busy_enabled] do
          true -> :rx
          _ -> :off
        end
      end

    "busyTxIndicator #{led_state}"
  end
end
