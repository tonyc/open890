defmodule Open890Web.Components.AtuIndicator do
  use Phoenix.Component

  def atu_indicator(assigns) do
    ~H"""
      <div class="atuIndicator">
        <span class="rx_indicator segment"><%= if @rx_enabled do %>R◀<% end %></span>
        <span class="center segment">AT</span>
        <span class="tx_indicator segment">▶T</span>
      </div>
    """
  end

end
