defmodule Open890Web.Components.MhzButton do
  use Phoenix.Component
  import Open890Web.Components.Buttons

  def mhz_button(assigns) do
    ~H"""
      <span class="indicator">
        <%= if @enabled do %>
          <.cmd_button cmd="MH0" classes="mini mhz-button enabled">MHz</.cmd_button>
        <% else %>
          <.cmd_button cmd="MH1" classes="mini inverted secondary mhz-button">MHz</.cmd_button>
        <% end %>
      </span>
    """
  end
end
