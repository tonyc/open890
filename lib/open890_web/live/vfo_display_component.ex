defmodule Open890Web.Live.VFODisplayComponent do
  use Open890Web, :live_component

  def render(assigns) do
    ~L"""
      <%= if @active_receiver == :a do %>
        <%= vfo_mem_indicator(@vfo_memory_state) %>
        <%= mode_indicator(@active_mode) %>
        <div id="ActiveVFO" class="freq active"><%= @active_frequency |> format_raw_frequency() %></div>
        <div class="bandIndicator">
          <div class="receiver">
            <span class="bandPointer">◀</span>
            <span class="receiverIndicator active">A</span>
            <span class="bandPointer"> </span>
          </div>
          <div>
            <span class="bandPointer"></span>
            <span class="receiverIndicator">B</span>
            <span class="bandPointer">▶</span>
          </div>
        </div>
        <%= mode_indicator(@inactive_mode) %>
        <div class="freq inactive"><%= @inactive_frequency |> format_raw_frequency() %></div>
      <% else %>
        <%= vfo_mem_indicator(@vfo_memory_state) %>
        <%= mode_indicator(@active_mode) %>
        <div id="ActiveVFO" class="freq active"><%= @active_frequency |> format_raw_frequency() %></div>
        <div class="bandIndicator">
          <div class="receiver">
            <span class="bandPointer"></span>
            <span class="receiverIndicator">A</span>
            <span class="bandPointer">▶</span>
          </div>
          <div>
            <span class="bandPointer">◀</span>
            <span class="receiverIndicator active">B</span>
            <span class="bandPointer"> </span>
          </div>
        </div>
        <%= mode_indicator(@inactive_mode) %>
        <div class="freq inactive"><%= @inactive_frequency |> format_raw_frequency() %></div>
      <% end %>
    """
  end

end
