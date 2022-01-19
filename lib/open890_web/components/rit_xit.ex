defmodule Open890Web.Components.RitXit do
  use Phoenix.Component
  alias Open890Web.{RadioViewHelpers}
  import Open890Web.Components.Buttons

  def rit_xit(assigns) do
    ~H"""
      <div class="ui grid">
        <div class="row">
          <div class="column three wide"></div>

          <div class="four wide right aligned column">
            <span class="indicator">
              <%= if @rit_enabled do %>
                <.cmd_button_2 cmd="RT0" classes="mini grey rit_xit">RIT</.cmd_button_2>
              <% else %>
                <.cmd_button_2 cmd="RT1" classes="mini inverted secondary rit_xit">RIT</.cmd_button_2>
              <% end %>
            </span>
            <span class="indicator">
              <%= if @xit_enabled do %>
                <.cmd_button_2 cmd="XT0" classes="mini grey rit_xit">XIT</.cmd_button_2>
              <% else %>
                <.cmd_button_2 cmd="XT1" classes="mini inverted secondary rit_xit">XIT</.cmd_button_2>
              <% end %>
            </span>
          </div>

          <div class="column two wide right aligned">
            <span class={rit_xit_offset_class(@rit_enabled, @xit_enabled)} phx-hook="RitXitControl" id="RitXitControl">
              <%= @offset |> RadioViewHelpers.format_rit_xit() %>
            </span>

          </div>
          <div class="column seven wide">
            <.cmd_button_2 cmd="RC">CLR</.cmd_button_2>
          </div>
        </div>

      </div>
    """
  end

  def rit_xit_offset_class(rit_enabled, xit_enabled) do
    if rit_enabled || xit_enabled do
      "rit_xit_offset hover-pointer active"
    else
      "rit_xit_offset hover-pointer inactive"
    end
  end
end
