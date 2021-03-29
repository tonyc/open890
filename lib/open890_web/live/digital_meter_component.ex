defmodule Open890Web.Live.DigitalMeterComponent do
  use Open890Web, :live_component

  def render(assigns) do
    ~L"""
      <svg id="sMeter" class="" viewbox="0 0 350 35">
        <mask id="m">
          <%= for x <- (0..70) do %>
            <rect x="<%= (x * 5) - 2 %>" y="-3" width="2" height="25" fill="white" />
          <% end %>
        </mask>

        <g id="sMeterLegend" transform="translate(0 2)">
          <line class="low" x1="0" y1="0" x2="172" y2="0" />
          <line class="high" x1="175" y1="0" x2="348" y2="0" />

          <g id="levelPips">
            <line class="pip low s1" x1="12" x2="12" y1="0" y2="5" />
            <line class="pip low s3" x1="52" x2="52" y1="0" y2="5" />
            <line class="pip low s5" x1="92" x2="92" y1="0" y2="5" />
            <line class="pip low s7" x1="132" x2="132" y1="0" y2="5" />
            <line class="pip low s9" x1="172" x2="172" y1="0" y2="5" />
            <line class="pip high plus20" x1="232" x2="232" y1="0" y2="5" />
            <line class="pip high plus40" x1="288" x2="288" y1="0" y2="5" />
            <line class="pip high plus60" x1="348" x2="348" y1="0" y2="5" />
          </g>

          <g transform="translate(0 13)">
            <text class="low s1" x="10" y="0">1</text>
            <text class="low s3" x="49" y="0">3</text>
            <text class="low s5" x="90" y="0">5</text>
            <text class="low s7" x="130" y="0">7</text>
            <text class="low s9" x="170" y="0">9</text>
            <text class="high plus20" x="223" y="0">+20</text>
            <text class="high plus40" x="279" y="0">+40</text>
            <text class="high plus60" x="323" y="0">+60dB</text>
          </g>
        </g>

        <g transform="translate(0 20)">
          <rect x="0" y="0" width="350" height="15" class="meterBG" />
          <rect x="0" y="0" width="<%= (@s_meter * 5) %>" height="15" class="meter low" />
          <%= if @s_meter > 35 do %>
            <rect x="175" y="0" width="<%= (@s_meter * 5) - 175 %>" height="15" class="meter high" />
          <% end %>

          <rect x="0" y="-2" width="350" height="25" fill="black" mask="url(#m)" />
        </g>
      </svg>
      <svg id="alcMeter" viewbox="0 0 350 35">
        <g id="alcMeterLegend" transform="translate(0 10)">
          <line x1="0" y1="0" x2="75" y2="0" class="high" />
          <line x1="102" y1="0" x2="172" y2="0" class="high" />
          <text x="80" y="3">ALC</text>
        </g>

        <g transform="translate(0 20)">
          <rect x="0" y="0" width="350" height="15" class="meterBG" />
          <rect x="0" y="0" width="<%= (@alc_meter * 5) %>" height="15" class="meter low" />
          <%= if @alc_meter > 35 do %>
            <rect x="175" y="0" width="<%= (@alc_meter * 5) - 175 %>" height="15" class="meter high" />
          <% end %>
          <rect x="0" y="-2" width="350" height="25" fill="black" mask="url(#m)" />
        </g>
      </svg>

      <svg id="swrMeter" viewbox="0 0 350 35">
        <g id="swrMeterLegend" class="meterLegend" transform="translate(0 15)">
          <text y="0" x="0">1</text>
          <text y="0" x="28">1.5</text>
          <text y="0" x="90">2</text>
          <text y="0" x="170">3</text>
          <text y="0" x="335" class="inf">∞</text>
        </g>

        <g transform="translate(0 20)">
          <rect x="0" y="0" width="350" height="15" class="meterBG" />
          <rect x="0" y="0" width="<%= (@swr_meter * 5) %>" height="15" class="meter low" />
          <%= if @swr_meter > 35 do %>
            <rect x="175" y="0" width="<%= (@swr_meter * 5) - 175 %>" height="15" class="meter high" />
          <% end %>
          <rect x="0" y="-2" width="350" height="25" fill="black" mask="url(#m)" />
        </g>
      </svg>
    """
  end
end
