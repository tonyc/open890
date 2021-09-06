defmodule Open890Web.Components.BandScope do
  # use Open890Web, :live_component
  use Phoenix.Component
  import Phoenix.HTML

  alias Open890Web.RadioViewHelpers

  def bandscope(assigns) do
    ~H"""
      <div id="bandScopeWrapper" class="hover-pointer" data-spectrum-scale={@spectrum_scale}>
        <svg id="bandScope" class="scope themed kenwood" viewbox="0 0 640 140">
          <defs>
            <filter id="blur" filterunits="userSpaceOnUse" x="0" y="0" width="640" height="150">
              <fegaussianblur in="sourceAlpha" stddeviation="1" />
            </filter>

            <lineargradient id="kenwoodBandScope" x1="0" y1="140" x2="0" y2="0" gradientunits="userSpaceOnUse">
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

          <%= band_scope_vertical_grid(@band_scope_mode, freq: @active_frequency, span: @band_scope_span) %>
          <%= band_scope_horizontal_grid() %>

          <polygon id="bandSpectrum" class="spectrum"
            vector-effect="non-scaling-stroke"
            points={RadioViewHelpers.scope_data_to_svg(@band_scope_data, max_value: 140, scale_y: @spectrum_scale)}  />

          <%= if @band_scope_edges do %>
            <g transform="translate(0 12)">
              <text class="bandEdge low" x="5" y="0"><%= @band_scope_edges |> format_band_scope_low() %></text>
              <text class="bandEdge high" x="635" y="0"><%= @band_scope_edges |> format_band_scope_high() %></text>
            </g>
          <% end %>

            <%= if @band_scope_edges && @filter_state do %>
              <.passband_polygon mode={@active_mode} active_frequency={@active_frequency} filter_state={@filter_state} scope_edges={@band_scope_edges} />
              <.carrier_line frequency={@active_frequency} band_scope_edges={@band_scope_edges} />
            <% end %>

          <rect id="bandscopeBackground" x="0" y="0" height="150" width="1280" pointer-events="visibleFill" phx-hook="BandScope" />
        </svg>

        <canvas
          id="BandScopeCanvas"
          class="waterfall bandscope"
          phx-hook="BandScopeCanvas"
          data-theme={@theme}
          data-draw-interval={@draw_interval}
          data-max-value="140"
          width="1280"
          height="300"></canvas>
      </div>

    """
  end


  def band_scope_vertical_grid(:auto_scroll, _) do
    offset = 64

    ~e{
      <%= for i <- (1..9) do %>
        <line class="bandscopeGrid vertical" x1="<%= i * offset %>" y1="0" x2="<%= i * offset %>" y2="640" />
      <% end %>
    }
  end

  def band_scope_vertical_grid(:center, opts) when is_list(opts) do
    freq = opts |> Keyword.fetch!(:freq)
    span = opts |> Keyword.fetch!(:span)

    if is_nil(span) do
      ""
    else
      span_hz = span * 1000
      span_step_hz = div(span_hz, 10)
      half_span = div(span_hz, 2)

      low_edge = freq - half_span
      high_edge = freq + half_span

      first_marker = round_up_to_step(low_edge, span_step_hz)

      values =
        0..9
        |> Enum.map(fn i ->
          first_marker + i * span_step_hz
          # first_marker_projected + (i * grid_offset)
        end)
        |> Enum.map(fn f ->
          project_to_bandscope_limits(f, {low_edge, high_edge})
        end)

      ~e{
        <%= for i <- (0..9) do %>
          <line class="bandscopeGrid vertical" x1="<%= Enum.at(values, i) %>" y1="0" x2="<%= Enum.at(values, i) %>" y2="640" />
        <% end %>
      }
    end
  end

  def band_scope_vertical_grid(:fixed, _) do
    ""
  end

  def band_scope_vertical_grid(_, _) do
    ""
  end

  def band_scope_horizontal_grid do
    offset = 140 / 8

    ~e{
      <%= for i <- (1..7) do %>
        <line class="bandscopeGrid horizontal" x1="0" y1="<%= i * offset %>" x2="640" y2="<%= i * offset %>" />
      <% end %>
    }
  end

  def passband_polygon(%{
    mode: mode,
    active_frequency: active_frequency,
    filter_state: filter_state,
    scope_edges: scope_edges
    } = assigns) when mode in [:lsb, :usb] do

    filter_low =
      mode
      |> RadioViewHelpers.offset_frequency(active_frequency, filter_state.lo_width)
      |> project_to_bandscope_limits(scope_edges)

    filter_high =
      mode
      |> RadioViewHelpers.offset_frequency(active_frequency, filter_state.hi_shift)
      |> project_to_bandscope_limits(scope_edges)


    points = "#{filter_low},0 #{filter_high},0 #{filter_high},150 #{filter_low},150"

    ~H"""
      <polygon id="passband" points={points} />
    """
  end

  def passband_polygon(%{
    mode: mode,
    active_frequency: active_frequency,
    filter_state: filter_state,
    scope_edges: scope_edges
    } = assigns) when mode in [:cw, :cw_r] do

    half_width = (filter_state.lo_width / 2) |> round()

    shift =
      case mode do
        :cw_r -> -filter_state.hi_shift
        _ -> filter_state.hi_shift
      end

    filter_low =
      (active_frequency + half_width + shift) |> project_to_bandscope_limits(scope_edges)

    filter_high =
      (active_frequency - half_width + shift) |> project_to_bandscope_limits(scope_edges)

    points = "#{filter_low},0 #{filter_high},0 #{filter_high},150 #{filter_low},150"

    ~H"""
      <polygon id="passband" points={points} />
    """

  end

  def passband_polygon(assigns) do
    ~H"""
    """
  end

  def project_to_bandscope_limits(frequency, {low, high})
      when is_integer(frequency) and is_integer(low) and is_integer(high) do
    delta = high - low
    freq_delta = frequency - low
    percentage = freq_delta / delta
    percentage * 640
  end

  def project_to_bandscope_limits(_, _edges) do
    0
  end

  def carrier_line(%{frequency: frequency, band_scope_edges: band_scope_edges} = assigns) do
    loc = project_to_bandscope_limits(frequency, band_scope_edges)

    tri_ofs = 10
    tri_text_x = loc - 3

    rx_triangle_points = "#{loc},#{tri_ofs} #{loc - tri_ofs},0 #{loc + tri_ofs},0"

    ~H"""
      <line id="active_receiver_line" class="primaryCarrier" x1={loc} y1="0" x2={loc} y2="150" />
      <g id="rxTriangleGroup">
        <polygon class="rx triangle" points={rx_triangle_points} />
        <text class="rx triangleText" x={tri_text_x} y="7">R</text>
      </g>
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
end
