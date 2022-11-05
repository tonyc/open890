defmodule Open890Web.Components.LockButton do
  use Phoenix.Component
  import Open890Web.Components.Buttons

  def lock_button(assigns) do
    ~H"""
      <span class="indicator">
        <%= if @enabled do %>
          <.cmd_button_2 cmd="LK0" classes="mini lock-button enabled">LOCK</.cmd_button_2>
        <% else %>
          <.cmd_button_2 cmd="LK1" classes="mini inverted secondary lock-button">LOCK</.cmd_button_2>
        <% end %>
      </span>
    """
  end
end
