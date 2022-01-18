defmodule Open890Web.Components.BandscopeButtons do
  use Phoenix.Component
  use Phoenix.HTML

  import Open890Web.RadioViewHelpers
  import Open890Web.Components.Buttons

  def buttons(assigns) do
    ~H"""
          <div class="column">
            <.scope_mode_button band_scope_mode={@band_scope_mode} />
          </div>

          <div class="column">
            <.scope_range_button band_scope_mode={@band_scope_mode} band_scope_span={@band_scope_span} />
          </div>

          <div class="column">
            <%= case @band_scope_mode do %>
              <% :auto_scroll -> %>
                <.cmd_button cmd="BSE" class="ui small black compact button">Shift</.cmd_button>
              <% :fixed -> %>
                <.cmd_button cmd="BSE" class="ui small black compact button">MKR.CTR</.cmd_button>
              <% _ -> %>
                <%= "" %>
            <% end %>
          </div>


          <div class="column">
            <.ref_level_control value={@ref_level} />
          </div>

          <div class="column">
            <.band_scope_att_button band_scope_att={@band_scope_att} />
          </div>

          <div class="column">
            <.band_scope_avg_button band_scope_avg={@band_scope_avg} />
          </div>

          <div class="column">
            <.waterfall_speed_control value={@waterfall_draw_interval} />
          </div>

          <div class="column">
            <.spectrum_scale_control value={@spectrum_scale} />
          </div>

          <div class="column">
            <.data_speed_control value={@data_speed} />
          </div>

          <div class="column">
            <.pop_out_bandscope_button popout={@popout} radio_connection={@radio_connection} />
          </div>

          <div class="six wide column"></div>

    """
  end
end
