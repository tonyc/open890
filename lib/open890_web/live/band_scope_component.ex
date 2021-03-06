defmodule Open890Web.Live.BandScopeComponent do
  use Open890Web, :live_component

  def render(assigns) do
    ~L"""
      <div id="bandScopeWrapper" class="hover-pointer" data-spectrum-scale="<%= @spectrum_scale %>">
        <svg id="bandScope" class="scope themed <%= @theme %>" viewbox="0 0 640 140">
          <defs>
            <filter id="blur" filterUnits="userSpaceOnUse" x="0" y="0" width="640" height="150">
              <feGaussianBlur in="sourceAlpha" stdDeviation="1" />
            </filter>
            <linearGradient id="kenwood" gradientUnits="userSpaceOnUse">
              <stop offset="0" stop-color="rgba(3, 3, 86, 1.0)" />
              <stop offset="1" stop-color="rgba(242, 242, 242, 1.0)" />
            </linearGradient>
          </defs>

          <%= band_scope_vertical_grid(@band_scope_mode, freq: @active_frequency, span: @band_scope_span) %>
          <%= band_scope_horizontal_grid() %>

          <polygon id="bandSpectrum" class="spectrum" points="<%= scope_data_to_svg(@band_scope_data, max_value: 140, scale_y: @spectrum_scale) %>" vector-effect="non-scaling-stroke" />

          <%= if @band_scope_edges do %>
            <g transform="translate(0 12)">
              <text class="bandEdge low" x="5" y="0"><%= @band_scope_edges |> format_band_scope_low() %></text>
              <text class="bandEdge high" x="635" y="0"><%= @band_scope_edges |> format_band_scope_high() %></text>
            </g>
          <% end %>

            <%= if @band_scope_edges && @filter_hi_shift && @filter_lo_width do %>
              <%= passband_polygon(@active_mode, @active_frequency, @filter_lo_width, @filter_hi_shift, @band_scope_edges) %>
              <%= carrier_line(@active_frequency, @band_scope_edges) %>
            <% end %>

          <rect id="bandscopeBackground" x="0" y="0" height="150" width="1280" pointer-events="visibleFill" phx-hook="BandScope" />
        </svg>

        <canvas
          id="BandScopeCanvas"
          class="waterfall bandscope"
          phx-hook="BandScopeCanvas"
          data-theme="<%= @theme %>"
          data-draw-interval="<%= @draw_interval %>"
          data-max-value="140"
          width="1280"
          height="300"></canvas>
      </div>

    """
  end
end
