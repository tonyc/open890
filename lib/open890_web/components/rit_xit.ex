defmodule Open890Web.Components.RitXit do
  use Phoenix.Component
  alias Open890Web.{RadioViewHelpers}

  def rit_xit(assigns) do
    ~H"""
      <div class="ui grid">
        <div class="row">
          <div class="column three wide"></div>

          <div class="four wide right aligned column">
            <span class="indicator">
              <%= if @rit_enabled do %>
                <button class="ui mini grey button rit_xit">RIT</button>
              <% else %>
                <button class="ui mini inverted secondary button rit_xit">RIT</button>
              <% end %>
            </span>
            <span class="indicator">
              <%= if @xit_enabled do %>
                <button class="ui mini grey button rit_xit">XIT</button>
              <% else %>
                <button class="ui mini inverted secondary button rit_xit">XIT</button>
              <% end %>
            </span>
          </div>

          <div class="column two wide right aligned">
            <span class={rit_xit_offset_class(@rit_enabled, @xit_enabled)} phx-hook="RitXitControl" id="RitXitControl">
              <%= @offset |> RadioViewHelpers.format_rit_xit() %>
            </span>

          </div>
          <div class="column seven wide">
            <button class="ui mini black button rit_xit_clr">CLR</button>
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
