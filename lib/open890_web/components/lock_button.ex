defmodule Open890Web.Components.LockButton do
  use Phoenix.Component
  import Open890Web.Components.Buttons

  def lock_button(assigns) do
    ~H"""
      <span class="indicator">
        <%= if @enabled do %>
          <.cmd_button cmd="LK0" classes="mini lock-button enabled">LOCK</.cmd_button>
        <% else %>
          <.cmd_button cmd="LK1" classes="mini inverted secondary lock-button">LOCK</.cmd_button>
        <% end %>
      </span>
    """
  end
end
