defmodule Open890Web.Live.BandIndicatorComponent do
  use Open890Web, :live_component

  def render(assigns) do
    ~H"""
      <div class="bandIndicator">
        <%= if @active_receiver == :a do %>
          <div>
            <span class="bandPointer">◀</span>
            <span class="receiverIndicator active">A</span>
            <span class="bandPointer"> </span>
          </div>
          <div>
            <span class="bandPointer"></span>
            <span class="receiverIndicator">B</span>
            <span class="bandPointer">▶</span>
          </div>
        <% else %>
          <div>
            <span class="bandPointer"></span>
            <span class="receiverIndicator">A</span>
            <span class="bandPointer">▶</span>
          </div>
          <div>
            <span class="bandPointer">◀</span>
            <span class="receiverIndicator active">B</span>
            <span class="bandPointer"> </span>
          </div>
        <% end %>
      </div>
    """
  end
end
