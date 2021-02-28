defmodule Open890Web.Live.AudioScopeComponent do
  use Open890Web, :live_component

  def render(assigns) do
    ~L"""
      <div id="audioScopeWrapper" class="hover-pointer">
        <svg id="audioScope" class="scope themed <%= @theme %>" viewbox="0 0 212 50" phx-hook="AudioScope">
          <defs>
            <linearGradient id="kenwood" gradientTransform="rotate(90)">
              <stop offset="0" stop-color="white" />
              <stop offset="50" stop-color="#0c0c5c" />
            </linearGradient>
          </defs>

          <text><%= @active_if_filter %></text>

          <polygon id="audioSpectrum" class="spectrum" points="<%= scope_data_to_svg(@audio_scope_data, 50) %>" vector-effect="non-scaling-stroke" />

          <%= if @active_if_filter && @roofing_filter_data[@active_if_filter] do %>
            <%= audio_scope_filter_edges(@active_mode, {@filter_lo_width, @filter_hi_shift}, @active_if_filter, @roofing_filter_data) %>
          <% end %>

          <line id="audioScopeTuneIndicator" class="primaryCarrier" x1="106" y1="5" x2="106" y2="50" />
        </svg>

        <canvas phx-hook="AudioScopeCanvas" id="AudioScopeCanvas" data-theme="<%= @theme %>" class="waterfall" width="213" height="50"></canvas>
      </div>
    """
  end
end
