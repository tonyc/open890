defmodule Open890Web.Components.FineButton do
  use Phoenix.Component
  import Open890Web.Components.Buttons

  def fine_button(assigns) do
    ~H"""
      <span class="indicator">
        <%= if @enabled do %>
          <.cmd_button cmd="FS0" classes="mini mhz-button fine-button enabled">FINE</.cmd_button>
        <% else %>
          <.cmd_button cmd="FS1" classes="mini inverted secondary mhz-button fine-button">FINE</.cmd_button>
        <% end %>
      </span>
    """
  end
end
