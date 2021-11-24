defmodule Open890Web.Live.NRIndicatorComponent do
  use Open890Web, :live_component

  def render(assigns) do
    ~H"""
      <div class="indicator nr">
        <%= if @nr && @nr !== :off do %>
          NR <span class="inverted"><%= format_nr_state(@nr) %></span>
        <% end %>
        &nbsp;
      </div>
    """
  end

  def format_nr_state(nr_state) do
    nr_state
    |> case do
      :off -> ""
      :nr_1 -> "1"
      :nr_2 -> "2"
    end
  end
end
