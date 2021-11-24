defmodule Open890Web.Live.BCIndicatorComponent do
  use Open890Web, :live_component
  import Open890Web.RadioViewHelpers

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

end
