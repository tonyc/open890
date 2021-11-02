defmodule Open890Web.Live.BCIndicatorComponent do
  use Open890Web, :live_component

  def render(assigns) do
    ~H"""
      <div class="indicator bc">
        <%= if @bc && @bc !== :off do %>
          BC <span class="inverted"><%= format_bc(@bc) %></span>
        <% end %>
        &nbsp;
      </div>
    """
  end

  def format_bc(bc_state) do
    bc_state
    |> case do
      :off -> ""
      :bc_1 -> "1"
      :bc_2 -> "2"
    end
  end
end
