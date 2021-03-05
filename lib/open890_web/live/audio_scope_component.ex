defmodule Open890Web.Live.AudioScopeComponent do
  use Open890Web, :live_component

  def render(assigns) do
    ~L"""
      <div id="audioScopeWrapper" class="hover-pointer _debug">
        <svg id="audioScope" class="scope themed <%= @theme %>" viewbox="0 0 212 60" phx-hook="AudioScope">
          <defs>
            <linearGradient id="kenwood" gradientTransform="rotate(90)">
              <stop offset="0" stop-color="white" />
              <stop offset="50" stop-color="#0c0c5c" />
            </linearGradient>
          </defs>

          <g transform="translate(0 10)">
            <polygon id="audioSpectrum" class="spectrum" points="<%= scope_data_to_svg(@audio_scope_data, 60) %>" vector-effect="non-scaling-stroke" />

            <%= if @active_if_filter && @roofing_filter_data[@active_if_filter] do %>
              <%= audio_scope_filter_edges(@active_mode, {@filter_lo_width, @filter_hi_shift}, @active_if_filter, @roofing_filter_data) %>
            <% end %>

            <line id="audioScopeTuneIndicator" class="primaryCarrier" x1="106" y1="5" x2="106" y2="60" />
          </g>

          <g transform="translate(3 10)">
            <text class="audioScopeLabel">
              <%= @active_if_filter |> to_string |> String.upcase() %>
            </text>

            <g transform="translate(20 0)">
              <text class="audioScopeLabel">
                <%= filter_lo_width_label(@active_mode) %>: <%= @filter_lo_width %>
              </text>
            </g>

            <g transform="translate(160 0)">
              <text class="audioScopeLabel">
                <%= if @active_mode in [:cw, :cw_r, :lsb, :lsb_d, :usb, :usb_d, :am, :fm] do %>
                  <%= filter_hi_shift_label(@active_mode) %>: <%= @filter_hi_shift %>
                <% end %>
              </text>
            </g>
          </g>

          <g transform="translate(90 10)">
            <text class="audioScopeLabel">
              RFT: <%= @roofing_filter_data[@active_if_filter] |> number_to_short() %>
            </text>
          </g>

        </svg>

        <canvas phx-hook="AudioScopeCanvas" id="AudioScopeCanvas" data-theme="<%= @theme %>" class="waterfall" width="213" height="60"></canvas>
      </div>
    """
  end

  def filter_lo_width_label(mode) when mode in [:cw, :cw_r, :fsk, :fsk_r, :psk, :psk_r] do
    "WIDTH"
  end

  def filter_lo_width_label(_) do
    "LC"
  end

  def filter_hi_shift_label(mode) when mode in [:cw, :cw_r] do
    "SHIFT"
  end

  def filter_hi_shift_label(_) do
    "HC"
  end
end
