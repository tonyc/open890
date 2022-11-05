defmodule Open890Web.Components.TxIndicator do
  use Phoenix.Component
  # alias Open890Web.{RadioViewHelpers}
  # import Open890Web.Components.Buttons

  def tx_indicator(assigns) do
    ~H"""
      <span class={tx_state_class(assigns)}>TX</span>
    """
  end

  def tx_state_class(assigns \\ %{}) do
    case assigns[:state] do
      :off -> "txIndicator"
      _ -> "txIndicator active"
    end
  end
end
