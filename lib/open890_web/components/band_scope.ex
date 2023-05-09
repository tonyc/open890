defmodule Open890Web.Components.BandScope do
  use Phoenix.Component
  require Logger

  alias Open890.FilterState
  alias Open890Web.RadioViewHelpers

  def bandscope(assigns) do
    ~H"""
      <div id="bandScopeWrapper" class="hover-pointer" data-spectrum-scale={@spectrum_scale}>
        <svg id="bandScope" class="scope themed kenwood" viewbox="0 0 640 160">
          <defs>
            <filter id="blur" filterunits="userSpaceOnUse" x="0" y="0" width="640" height="150">
              <fegaussianblur in="sourceAlpha" stddeviation="1" />
            </filter>

            <lineargradient id="kenwoodBandScope" x1="0" y1="160" x2="0" y2="0" gradientunits="userSpaceOnUse">
              <stop offset="0" stop-color="#030356" />
              <stop offset="45%" stop-color="#cdcdcd" />
            </lineargradient>

            <lineargradient id="plasma" x1="0" y1="140" x2="0" y2="0" gradientunits="userSpaceOnUse">
              <stop offset="0%" stop-color="black" />
              <stop offset="2%" stop-color="#8c00a0" />
              <stop offset="10%" stop-color="#e30084" />
              <stop offset="25%" stop-color="#ff2830" />
              <stop offset="40%" stop-color="#ffb56b" />
              <stop offset="50%" stop-color="white" />
            </lineargradient>
          </defs>

          <g transform="translate(0 20)">

            <%= if @band_scope_mode == :fixed do %>
              <.fixed_mode_vertical_grid edges={@band_scope_edges} />
            <% end %>

            <%= if @band_scope_mode == :auto_scroll do %>
              <.auto_scroll_mode_vertical_grid />
            <% end %>

            <%= if @band_scope_mode == :center do %>
              <.center_mode_vertical_grid freq={@effective_active_frequency} span={@band_scope_span} />
            <% end %>

            <.band_scope_horizontal_grid />

            <polygon id="bandSpectrum" class="spectrum" vector-effect="non-scaling-stroke" points={RadioViewHelpers.scope_data_to_svg(@band_scope_data, max_value: 140, scale_y: @spectrum_scale)}  />
          </g>

          <g transform="translate(0 15)">
            <%= for marker <- @markers do %>
              <.marker marker={marker} band_scope_edges={@band_scope_edges} />
            <% end %>
          </g>

          <%= if @tx_banner_frequency && @band_scope_edges do %>
            <%= if freq_low(@tx_banner_frequency, @band_scope_edges) do %>
              <g transform="translate(10 46),rotate(90)">
                <.tx_offscreen_indicator />
              </g>
            <% end %>

            <%= if freq_high(@tx_banner_frequency, @band_scope_edges) do %>
              <g transform="translate(630 46),rotate(-90)">
                <.tx_offscreen_indicator />
              </g>
            <% end %>
          <% end %>

          <g transform="translate(0 8)">
            <%= if @band_scope_edges do %>
              <text class="bandEdge low" x="5" y="0">
                <%= format_band_scope_low(@band_scope_edges) %>
              </text>
              <text class="bandEdge high" x="635" y="0">
                <%= format_band_scope_high(@band_scope_edges) %>
              </text>
              <text class="bandEdge span" x="450" y="0">
                Span: <%= effective_span(@band_scope_edges) %> kHz
              </text>
            <% end %>

            <%= if @effective_active_frequency do %>
              <text class="bandEdge mid" x="300" y="0"><%= format_active_frequency(@effective_active_frequency) %></text>
            <% end %>
          </g>

          <g transform="translate(0 20)">
            <%= if @band_scope_edges && @filter_state && @active_mode do %>
              <.passband_polygon
                mode={@active_mode}
                active_frequency={@rx_banner_frequency}
                filter_mode={@filter_mode}
                filter_state={@filter_state}
                scope_edges={@band_scope_edges} />

              <.carrier_line mode="tx" label="T" frequency={@tx_banner_frequency} band_scope_edges={@band_scope_edges} piggyback={!@split_enabled}/>
              <.carrier_line mode="rx" label="R" frequency={@rx_banner_frequency} band_scope_edges={@band_scope_edges} split_enabled={@split_enabled} />
            <% end %>

            <rect id="bandscopeBackground" x="0" y="0" height="150" width="1280" pointer-events="visibleFill" phx-hook="BandScope" data-locked={@lock_enabled} />
          </g>

        </svg>

        <canvas
          id="BandScopeCanvas"
          class="waterfall bandscope"
          phx-hook="BandScopeCanvas"
          data-theme={@theme}
          data-draw-interval={@draw_interval}
          data-max-value="140"
          width="1280"
          height="275"
          ></canvas>
      </div>

    """
  end

  def auto_scroll_mode_vertical_grid(assigns) do
    values = 1..9 |> Enum.map(fn x -> x * 64 end)

    ~H"""
      <%= for value <- values do %>
        <line class="bandscopeGrid vertical" x1={value} y1="0" x2={value} y2="640" />
      <% end %>
    """
  end

  def effective_span({low, high}) when is_integer(low) and is_integer(high) do
    ((high - low) / 1000) |> trunc()
  end

  def effective_span(_), do: nil

  def center_mode_vertical_grid(assigns) do
    ~H"""
      <%= for value <- compute_center_mode_grid_values(@freq, @span) do %>
        <line class="bandscopeGrid vertical" x1={value} y1="0" x2={value} y2="640" />
      <% end %>
    """
  end

  def compute_center_mode_grid_values(_freq, nil) do
    []
  end

  def compute_center_mode_grid_values(freq, span) do
    span_hz = span * 1000
    span_step_hz = div(span_hz, 10)
    half_span = div(span_hz, 2)

    low_edge = freq - half_span
    high_edge = freq + half_span

    first_marker = round_up_to_step(low_edge, span_step_hz)

    0..9
    |> Enum.map(fn i ->
      first_marker + i * span_step_hz
    end)
    |> Enum.map(fn f ->
      project_to_bandscope_limits(f, {low_edge, high_edge})
    end)
  end

  def marker(assigns) do
    marker = assigns.marker

    x = project_to_bandscope_limits(marker.freq, assigns.band_scope_edges)
    classes = "marker user vertical #{marker.color}"

    ~H"""
      <g class="user_marker_group" transform="translate(0 0)">
        <line id="marker-#{marker.id}" phx-hook="Marker" class={classes} x1={x} y1="0" x2={x+2} y2={"640"} pointer-events="visibleStroke" phx-click="marker_clicked" phx-value-id={marker.id} />

        <rect class="marker_delete" x={x-3} y="-2" height="4" width="6" pointer-events="visibleFill" phx-click="delete_user_marker" phx-value-id={marker.id}/>
      </g>
    """
  end

  def fixed_mode_vertical_grid(assigns) do
    ~H"""
      <%= for value <- compute_fixed_mode_grid_values(@edges) do %>
        <line class="bandscopeGrid vertical" x1={value} y1="0" x2={value} y2="640" />
      <% end %>
    """
  end

  def compute_fixed_mode_grid_values({low_edge, high_edge} = edges)
      when is_integer(low_edge) and is_integer(high_edge) do
    span_step_hz = (high_edge - low_edge) |> fixed_mode_step_hz()

    first_marker = round_up_to_step(low_edge, span_step_hz)

    first_marker..high_edge//span_step_hz
    |> Enum.map(fn f ->
      project_to_bandscope_limits(f, edges)
    end)
  end

  def compute_fixed_mode_grid_values(_) do
    []
  end

  def fixed_mode_step_hz(span_hz) do
    case div(span_hz, 1000) do
      x when x in 5..9 -> 500
      x when x in 10..19 -> 1000
      x when x in 20..29 -> 2000
      x when x in 30..49 -> 3000
      x when x in 50..99 -> 5000
      x when x in 100..199 -> 10000
      x when x in 200..499 -> 20000
      500 -> 50000
      _ -> 1000
    end
  end

  def band_scope_horizontal_grid(assigns) do
    offset = 140 / 8

    ~H"""
      <%= for i <- (0..7) do %>
        <line class="bandscopeGrid horizontal" x1="0" y1={i * offset} x2="640" y2={i * offset} />
      <% end %>
    """
  end

  def passband_polygon(
        %{
          mode: mode,
          active_frequency: active_frequency,
          filter_state: filter_state,
          filter_mode: filter_mode,
          scope_edges: scope_edges
        } = assigns
      ) do
    points =
      case mode do
        x when x in [:cw, :cw_r, :fsk, :fsk_r, :psk, :psk_r] ->
          shifted_passband_points(mode, filter_state, active_frequency, scope_edges)

        x when x in [:usb, :usb_d, :lsb, :lsb_d] ->
          hi_lo_cut_passband_points(
            mode,
            filter_state,
            active_frequency,
            scope_edges,
            filter_mode
          )

        _ ->
          # TODO: FIXME
          # Logger.warn("passband_polygon: unhandled mode #{mode}")
          ""
      end

    ~H"""
      <polygon id="passband" points={points} />
    """
  end

  def shifted_passband_points(
        mode,
        %FilterState{lo_width: lo_width, hi_shift: hi_shift} = _filter_state,
        active_frequency,
        scope_edges
      )
      when is_integer(lo_width) and is_integer(hi_shift) do
    half_width = (lo_width / 2) |> round()

    hi_shift =
      case mode do
        x when x in [:fsk, :fsk_r, :psk, :psk_r] ->
          # no shift in FSK/PSK
          0

        _ ->
          hi_shift
      end

    shift_direction =
      case mode do
        x when x in [:fsk, :fsk_r, :psk, :psk_r] ->
          # no shift in FSK/PSK
          0

        x when x in [:cw_r, :lsb, :lsb_d] ->
          -1

        x when x in [:usb, :usb_d, :cw] ->
          1

        other ->
          Logger.debug("Unhandled shifted_passband_points for mode #{inspect(other)}")
          1
      end

    shift = shift_direction * (hi_shift || 0)

    filter_low =
      (active_frequency + half_width + shift) |> project_to_bandscope_limits(scope_edges)

    filter_high =
      (active_frequency - half_width + shift) |> project_to_bandscope_limits(scope_edges)

    "#{filter_low},0 #{filter_high},0 #{filter_high},150 #{filter_low},150"
  end

  def shifted_passband_points(_mode, %FilterState{}, _active_frequency, _scope_edges) do
    ""
  end

  def hi_lo_cut_passband_points(
        mode,
        %FilterState{} = filter_state,
        active_frequency,
        scope_edges,
        filter_mode
      ) do
    points =
      case filter_mode do
        :hi_lo_cut ->
          filter_low =
            mode
            |> RadioViewHelpers.offset_frequency(active_frequency, filter_state.lo_width)
            |> project_to_bandscope_limits(scope_edges)

          filter_high =
            mode
            |> RadioViewHelpers.offset_frequency(active_frequency, filter_state.hi_shift)
            |> project_to_bandscope_limits(scope_edges)

          "#{filter_low},0 #{filter_high},0 #{filter_high},150 #{filter_low},150"

        :shift_width ->
          shifted_passband_points(mode, filter_state, active_frequency, scope_edges)

        _ ->
          Logger.debug(
            "Unknown mode/filter mode combination: #{inspect(mode)}/#{inspect(filter_mode)}"
          )

          ""
      end

    points
  end

  def project_to_bandscope_limits(frequency, {low, high})
      when is_integer(frequency) and is_integer(low) and is_integer(high) do
    delta = high - low
    freq_delta = frequency - low
    percentage = freq_delta / delta
    percentage * 640
  end

  def project_to_bandscope_limits(_, _), do: 0

  def carrier_line(
        %{frequency: frequency, band_scope_edges: band_scope_edges, mode: mode} = assigns
      ) do
    loc = project_to_bandscope_limits(frequency, band_scope_edges)

    tri_ofs = 10
    tri_text_x = loc - 3

    triangle_points = "#{loc},#{tri_ofs} #{loc - tri_ofs},0 #{loc + tri_ofs},0"

    label_translate =
      case assigns[:piggyback] do
        true -> "translate(0 -#{tri_ofs})"
        _ -> "translate(0 0)"
      end

    label =
      case mode do
        "tx" -> "T"
        _ -> "R"
      end

    ~H"""
      <line class={add_mode(mode, "carrier")} x1={loc} y1="0" x2={loc} y2="150" />
      <g class={add_mode(mode, "triangleGroup")} transform={label_translate}>
        <polygon class={add_mode(mode, "triangle")} points={triangle_points} />
        <text class={add_mode(mode, "triangleText")} x={tri_text_x} y="7"><%= label %></text>
      </g>
    """
  end

  def add_mode(mode, str) do
    str <> " " <> mode
  end

  def tx_offscreen_indicator(assigns) do
    ~H"""
      <polygon class="txOffscreen" points="0 10,-8 0,8 0"/>
    """
  end

  def round_up_to_step(value, step) when is_integer(value) and is_integer(step) do
    div(value, step) * step + step
  end

  def format_band_scope_low({low, _high}) do
    low |> RadioViewHelpers.format_raw_frequency()
  end

  def format_band_scope_high({_low, high}) do
    high |> RadioViewHelpers.format_raw_frequency()
  end

  def format_active_frequency(freq) do
    freq |> RadioViewHelpers.format_raw_frequency()
  end

  def freq_low(freq, edges) do
    {low, _} = edges

    freq < low
  end

  def freq_high(freq, edges) do
    {_, high} = edges

    freq > high
  end
end
