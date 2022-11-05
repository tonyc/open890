defmodule Open890Web.Components.RitXit do
  use Phoenix.Component
  alias Open890Web.{RadioViewHelpers}
  import Open890Web.Components.Buttons

  def offset_indicator(assigns) do
    ~H"""
      <span
        class={offset_class(@rit_enabled, @xit_enabled)}
        phx-hook="RitXitControl" id="RitXitControl">
        <%= @offset |> RadioViewHelpers.format_rit_xit() %>
      </span>
    """
  end

  def rit_button(assigns) do
    ~H"""
      <span class="indicator">
        <%= if @enabled do %>
          <.cmd_button_2 cmd="RT0" classes="mini enabled green rit_button">RIT</.cmd_button_2>
        <% else %>
          <.cmd_button_2 cmd="RT1" classes="mini inverted secondary rit_button">RIT</.cmd_button_2>
        <% end %>
      </span>
    """
  end

  def xit_button(assigns) do
    ~H"""
      <span class="indicator">
        <%= if @enabled do %>
          <.cmd_button_2 cmd="XT0" classes="mini enabled green xit_button">XIT</.cmd_button_2>
        <% else %>
          <.cmd_button_2 cmd="XT1" classes="mini inverted secondary xit_button">XIT</.cmd_button_2>
        <% end %>
      </span>
    """
  end

  def clear_button(assigns) do
    ~H"""
      <.cmd_button_2 cmd="RC" classes="mini inverted secondary">CL</.cmd_button_2>
    """
  end

  def offset_class(rit_enabled, xit_enabled) do
    if rit_enabled || xit_enabled do
      "rit_xit_offset hover-pointer active"
    else
      "rit_xit_offset hover-pointer inactive"
    end
  end
end
