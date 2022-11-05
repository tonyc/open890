defmodule Open890Web.Components.SplitButton do
  use Phoenix.Component
  import Open890Web.Components.Buttons

  def split_button(assigns) do
    ~H"""
      <span class="indicator">
        <%= if @enabled do %>
          <.cmd_button_2 cmd="TB0" classes="mini split-button enabled">SPLIT</.cmd_button_2>
        <% else %>
          <.cmd_button_2 cmd="TB1" classes="mini inverted secondary split-button">SPLIT</.cmd_button_2>
        <% end %>
      </span>
    """
  end
end
