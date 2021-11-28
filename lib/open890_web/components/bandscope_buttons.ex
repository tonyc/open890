defmodule Open890Web.Components.BandscopeButtons do
  use Phoenix.Component
  use Phoenix.HTML

  import Open890Web.RadioViewHelpers
  import Open890Web.Components.Buttons

  def buttons(assigns) do
    ~H"""
      <div class="scopeButtons">
        <.scope_mode_button band_scope_mode={@band_scope_mode} />

        <.scope_range_button band_scope_mode={@band_scope_mode} band_scope_span={@band_scope_span} />

        <%= case @band_scope_mode do %>
          <% :auto_scroll -> %>
            <.cmd_button_2 cmd="BSE" class="ui small black compact button">Shift</.cmd_button_2>
          <% :fixed -> %>
            <.cmd_button_2 cmd="BSE" class="ui small black compact button">MKR.CTR</.cmd_button_2>
          <% _ -> %>
            <%= "" %>
        <% end %>


        <.ref_level_control value={@ref_level} />

        <.band_scope_att_button band_scope_att={@band_scope_att} />

        <.band_scope_avg_button band_scope_avg={@band_scope_avg} />

        <.waterfall_speed_control value={@waterfall_draw_interval} />

        <.spectrum_scale_control value={@spectrum_scale} />

        <.data_speed_control value={@data_speed} />

        <.pop_out_bandscope_button popout={@popout} radio_connection={@radio_connection} />
      </div> <!-- ui buttons -->
    """
  end
end
