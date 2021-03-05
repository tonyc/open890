defmodule Open890Web.Live.VFODisplayComponent do
  use Open890Web, :live_component

  alias Open890Web.Live.BandIndicatorComponent

  def render(assigns) do
    ~L"""
      <div class="vfos">
        <%= vfo_mem_indicator(@vfo_memory_state) %>
        <%= mode_indicator(@active_mode) %>
        <div id="ActiveVFO" class="freq active"><%= @active_frequency |> format_raw_frequency() %></div>
        <%= live_component @socket, BandIndicatorComponent, active_receiver: @active_receiver %>
        <%= mode_indicator(@inactive_mode) %>
        <div class="freq inactive"><%= @inactive_frequency |> format_raw_frequency() %></div>
      </div>
    """
  end
end
