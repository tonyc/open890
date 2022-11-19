defmodule Open890Web.Components.Meter do
  use Phoenix.Component

  # range of motion in degrees of the analog needle
  @needle_angle_range 90
  @needle_pivot_y 155

  def meter(assigns) do
      # digital_meter(assigns)
      analog_meter(assigns)
  end

  def analog_meter(assigns) do
    # @s_meter is the 0-70 value
    meter = assigns[:s_meter] || 0
    meter_old = assigns[:s_meter_old] || 0
    meter_width = 272
    middle = meter_width / 2

    smeter_cx = middle
    smeter_cy = 375

    ~H"""
      <div class="sMeterWrapper analog">
        <svg id="sMeter" class="analog" viewbox="0 0 272 108">
          <defs>
            <filter id="dropshadow" filterunits="userSpaceOnUse" x="0" y="0" width="100%" height="100%">
              <fegaussianblur in="sourceAlpha" stddeviation="3" />
            </filter>
          </defs>

          <g class="sMeterLegend">
            <circle class="scale smeter" cx={middle} cy={smeter_cy} r="345" />

            <g transform={rotate(-18, smeter_cx, smeter_cy)}>
              <text class="legend" y="15" x={middle - 8}>S</text>
              <line class="scale" x1={middle} y1="30" x2={middle} y2="20" />
            </g>

            <g transform={rotate(-16.5, smeter_cx, smeter_cy)}>
              <text class="legend" y="15" x={middle - 3}>1</text>
              <line class="scale major" x1={middle} y1="30" x2={middle} y2="20" />
            </g>

            <g transform={rotate(-14.25, smeter_cx, smeter_cy)}>
              <line class="scale" x1={middle} y1="30" x2={middle} y2="25" />
            </g>

            <g transform={rotate(-12, smeter_cx, smeter_cy)}>
              <text class="legend" y="15" x={middle - 3}>3</text>
              <line class="scale major" x1={middle} y1="30" x2={middle} y2="20" />
            </g>

            <g transform={rotate(-10, smeter_cx, smeter_cy)}>
              <line class="scale" x1={middle} y1="30" x2={middle} y2="25" />
            </g>

            <g transform={rotate(-8, smeter_cx, smeter_cy)}>
              <text class="legend" y="15" x={middle - 3}>5</text>
              <line class="scale major" x1={middle} y1="30" x2={middle} y2="20" />
            </g>

            <g transform={rotate(-6, smeter_cx, smeter_cy)}>
              <line class="scale" x1={middle} y1="30" x2={middle} y2="25" />
            </g>

            <g transform={rotate(-4, smeter_cx, smeter_cy)}>
              <text class="legend" y="15" x={middle - 3}>7</text>
              <line class="scale major" x1={middle} y1="30" x2={middle} y2="20" />
            </g>

            <g transform={rotate(-2, smeter_cx, smeter_cy)}>
              <line class="scale" x1={middle} y1="30" x2={middle} y2="25" />
            </g>

            <g>
              <text class="legend" y="15" x={middle - 3}>9</text>
              <line class="scale major" x1={middle} y1="30" x2={middle} y2="20" />
            </g>

            <g transform={rotate(2.625, smeter_cx, smeter_cy)}>
              <line class="scale high" x1={middle} y1="30" x2={middle} y2="25" />
            </g>

            <g transform={rotate(5.25, smeter_cx, smeter_cy)}>
              <text class="legend high" y="15" x={middle - 9}>+20</text>
              <line class="scale high major" x1={middle} y1="30" x2={middle} y2="20" />
            </g>

            <g transform={rotate(8.125, smeter_cx, smeter_cy)}>
              <line class="scale high" x1={middle} y1="30" x2={middle} y2="25" />
            </g>

            <g transform={rotate(11, smeter_cx, smeter_cy)}>
              <text class="legend high" y="15" x={middle - 9}>+40</text>
              <line class="scale high major" x1={middle} y1="30" x2={middle} y2="20" />
            </g>

            <g transform={rotate(14.5, smeter_cx, smeter_cy)}>
              <line class="scale high" x1={middle} y1="30" x2={middle} y2="25" />
            </g>


            <g transform={rotate(18, smeter_cx, smeter_cy)}>
              <text class="legend high" y="15" x={middle - 12}>+60 dB</text>
              <line class="scale high major" x1={middle} y1="30" x2={middle} y2="20" />
            </g>
            <!--
            <circle class="scale po" cx={half_width} cy="380" r="345" />
            <circle class="scale swr" cx={half_width} cy="390" r="345" />
            <circle class="scale id" cx={half_width} cy="405" r="345" />
            <circle class="scale comp" cx={half_width} cy="410" r="345" />
            -->
          </g>

          <g transform="">
            <line class="needle dropshadow" x1={middle} y1="5" x2={middle} y2="155" filter="url(#dropshadow)">
              <animateTransform
                attributeName="transform"
                attributeType="XML"
                type="rotate"
                from={needle_rotate(meter_old, meter_width)}
                to={needle_rotate(meter, meter_width)}
                calcMode="paced"
                dur="0.5s"
                fill="freeze"
              />
            </line>
            <line class="needle" x1={middle} y1="5" x2={middle} y2="155">
              <animateTransform
                attributeName="transform"
                attributeType="XML"
                type="rotate"
                from={needle_rotate(meter_old, meter_width)}
                to={needle_rotate(meter, meter_width)}
                calcMode="paced"
                dur="0.5s"
                fill="freeze"
              />
            </line>
            <!--
            <line class="needle alt" x1={half_width} y1="5" x2={half_width} y2="155">
              <animateTransform
                attributeName="transform"
                attributeType="XML"
                type="rotate"
                from={needle_rotate(meter_old, meter_width)}
                to={needle_rotate(meter, meter_width)}
                fill="freeze"
                dur="1s"
              />
            </line>
            -->
          </g>
        </svg>
      </div>
    """
  end

  def rotate(deg, x, y) do
    "rotate(#{deg}, #{x}, #{y})"
  end

  def needle_rotate(value, meter_width) do
    angle = (needle_angle_range() / 70.0 * value) - (needle_angle_range() / 2.0)
    x_offset = meter_width / 2

    # "rotate(#{angle}, #{x_offset}, #{needle_pivot_y()})"

    [angle, x_offset, needle_pivot_y()] |> Enum.join(" ")
  end

  def needle_angle_range, do: @needle_angle_range
  def needle_pivot_y, do: @needle_pivot_y

  def digital_meter(assigns) do
    ~H"""
      <div class="sMeterWrapper digital">
        <svg id="sMeter" class="digital" viewbox="0 0 350 35">
          <mask id="m">
            <%= for x <- (0..70) do %>
              <rect x={pip_x_offset(x)} y="-3" width="2" height="25" fill="white" />
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
            <rect x="0" y="0" width={meter_low_width(@s_meter)} height="15" class="meter low" />
            <%= if @s_meter > 35 do %>
              <rect x="175" y="0" width={meter_high_width(@s_meter)} height="15" class="meter high" />
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
            <rect x="0" y="0" width={meter_low_width(@alc_meter)} height="15" class="meter low" />
            <%= if @alc_meter > 35 do %>
              <rect x="175" y="0" width={meter_high_width(@alc_meter)} height="15" class="meter high" />
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
            <rect x="0" y="0" width={meter_low_width(@swr_meter)} height="15" class="meter low" />
            <%= if @swr_meter > 35 do %>
              <rect x="175" y="0" width={meter_high_width(@swr_meter)} height="15" class="meter high" />
            <% end %>
            <rect x="0" y="-2" width="350" height="25" fill="black" mask="url(#m)" />
          </g>
        </svg>
      </div>
    """
  end

  def pip_x_offset(x) do
    x * 5 - 1
  end

  def meter_low_width(val) do
    val * 5
  end

  def meter_high_width(val) do
    val * 5 - 175
  end
end
