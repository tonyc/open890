defmodule Open890Web.Components.BandscopeButtons do
  use Phoenix.Component
  import Open890Web.RadioViewHelpers

  def buttons(assigns) do
    ~H"""
      <div class="scopeButtons">

        <%= if @band_scope_mode do %>
          <%= cycle_label_button("", @band_scope_mode,
            %{
              auto_scroll: %{label: "Auto Scroll", cmd: "BS30"},
              fixed: %{label: "Fixed", cmd: "BS32"},
              center: %{label: "Center", cmd: "BS31"}
            }, class: "small compact black") %>
        <% end %>

        <%= if @band_scope_mode == :fixed do %>
          <button class="ui black button">Range: (fixme)</button>
        <% else %>
          <div class="ui small compact labeled buttons">
            <%= cycle_button("▼", @band_scope_span,
              %{
                5 => "BS47",
                10 => "BS40",
                20 => "BS41",
                30 => "BS42",
                50 => "BS43",
                100 => "BS44",
                200 => "BS45",
                500 => "BS46"
              }, class: "black") %>
              %>
              <div class="ui black button">
                Span: <%= @band_scope_span %> kHz
              </div>
              <%= cycle_button "▲", @band_scope_span,
              %{
                5 => "BS41",
                10 => "BS42",
                20 => "BS43",
                30 => "BS44",
                50 => "BS45",
                100 => "BS46",
                200 => "BS47",
                500 => "BS40",
              }, class: "black" %>
          </div>
        <% end %>

        <%= case @band_scope_mode do %>
          <% :auto_scroll -> %>
            <%= cmd_button "Shift", "BSE", class: "ui small black compact button" %>
          <% :fixed -> %>
            <%= cmd_button "MKR.CTR", "BSE", class: "ui small compact black button" %>
          <% _ -> %>
            <%= "" %>
        <% end %>

        <div class="ui small compact black button" id="RefLevelControl">
          <form class="" id="refLevel" phx-change="ref_level_changed">
            Ref Level
            <input class="miniTextInput" name="refLevel" type="number" min="-20" max="10" step="0.5" value={format_ref_level(@ref_level)} />
            dB
          </form>
        </div>

        <%= if @band_scope_att do %>
          <div class="ui small compact black buttons">
            <%= cycle_button "▼", @band_scope_att,
              %{
                0 => "BS83",
                1 => "BS80",
                2 => "BS81",
                3 => "BS82",
              } %>
            <div class="ui button">
              Scope ATT:
              <%= format_band_scope_att(@band_scope_att) %>
            </div>
            <%= cycle_button "▲", @band_scope_att,
              %{
                0 => "BS81",
                1 => "BS82",
                2 => "BS83",
                3 => "BS80",
              } %>
          </div>
        <% end %>

        <%= if @band_scope_avg do %>
          <div class="ui small compact black buttons">
            <%= cycle_button "▼", @band_scope_avg,
              %{
                0 => "BSA3",
                1 => "BSA0",
                2 => "BSA1",
                3 => "BSA2",
              } %>
            <div class="ui button">
              Scope Avg: <%= @band_scope_avg %>
            </div>
            <%= cycle_button "▲", @band_scope_avg,
              %{
                0 => "BSA1",
                1 => "BSA2",
                2 => "BSA3",
                3 => "BSA0",
              } %>
          </div>
        <% end %>

        <div class="ui small compact black button">
          <form id="WaterfallSpeed" phx-hook="WaterfallSpeedForm">
            WF Speed: 1 /
            <input class="miniTextInput" name="value" type="number" min="1" max="100" step="1" value={@waterfall_draw_interval} />
          </form>
        </div>

        <div class="ui small compact black button">
          <form id="SpectrumScale" phx-hook="SpectrumScaleForm">
            Spectrum Scale
            <input class="miniTextInput" name="value" type="number" min="1" max="10" step="0.1" value={@spectrum_scale} />
          </form>
        </div>

        <%= if @data_speed do %>
          <%= cycle_label_button("Data Speed", @data_speed,
            %{
              1 => %{label: "High", cmd: "DD03"},
              2 => %{label: "Mid", cmd: "DD01"},
              3 => %{label: "Low", cmd: "DD02"},
            }, class: "small compact black") %>
        <% end %>

      </div> <!-- ui buttons -->

    """
  end
end
