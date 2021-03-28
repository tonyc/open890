defmodule Open890Web.Live.VFODisplayComponent do
  use Open890Web, :live_component

  alias Open890Web.Live.BandIndicatorComponent

  def render(assigns) do
    ~L"""
      <div class="vfos ui stackable grid ">
        <div class="eight wide column _debug">
          <span class="vfoMemIndicator"><%= format_vfo_memory_state(@vfo_memory_state) %></span>
          <span class="modeIndicator active"><%= format_mode(@active_mode) %></span>
          <span class="freq active" phx-hook="ActiveVFO" id="ActiveVFO"><%= @active_frequency |> format_raw_frequency() %></span>
        </div>
        <div class="left aligned eight wide column computer only tablet only _debug">
          <%= live_component @socket, BandIndicatorComponent, active_receiver: @active_receiver %>
          <span><%= format_mode(@inactive_mode) %></span>
          <div class="freq inactive"><%= @inactive_frequency |> format_raw_frequency() %></div>
        </div>
      </div>
    """
  end

  def format_vfo_memory_state(state) do
    case state do
      :vfo -> "VFO"
      :memory -> "MEM"
      _ -> "UNKNOWN"
    end
  end

end
