defmodule Open890Web.Components.RitXit do
  use Phoenix.Component
  alias Open890Web.{RadioViewHelpers}

  def rit_xit(assigns) do
    ~H"""
      <div class="ui grid">
        <div class="row">
          <div class="column seven wide right aligned">

              <div class="column">
                <span class="indicator">
                  <%= if @rit_enabled do %>
                    <button class="ui mini grey button rit_xit">RIT</button>
                  <% else %>
                    <button class="ui mini inverted secondary button rit_xit">RIT</button>
                  <% end %>
                </span>
              </div>
              <div class="column">
                <span class="indicator">
                  <%= if @xit_enabled do %>
                    <button class="ui mini grey button rit_xit">XIT</button>
                  <% else %>
                    <button class="ui mini inverted secondary button rit_xit">XIT</button>
                  <% end %>
                </span>
              </div>

          </div>
          <div class="column two wide">

            <span class={rit_xit_offset_class(@rit_enabled, @xit_enabled)}>
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
      "rit_xit_offset active"
    else
      "rit_xit_offset inactive"
    end
  end
end
