defmodule Open890Web.Live.NotchIndicatorComponent do
  use Open890Web, :live_component

  alias Open890.NotchState

  def render(assigns) do
    ~H"""
      <div class="indicator notch">
        <%= if @notch_state.enabled do %>
          NOTCH
          <span class="notchWidth inverted"><%= format_notch_width(@notch_state) %></span>
        <% end %>
        &nbsp;
      </div>
    """
  end

  def format_notch_width(%NotchState{width: width} = _notch_state) do
    case width do
      :narrow -> "N"
      :mid -> "M"
      :wide -> "W"
      _ -> ""
    end
  end
end
