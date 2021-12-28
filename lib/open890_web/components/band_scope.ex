defmodule Open890Web.Components.BandScope do
  # use Open890Web, :live_component
  use Phoenix.Component
  import Phoenix.HTML
  require Logger

  alias Open890Web.RadioViewHelpers

  def bandscope(assigns) do
    ~H"""
      <div id="bandScopeWrapper" class="hover-pointer" data-spectrum-scale={@spectrum_scale}>

        <p>bandscope: mode: <%= @active_mode %>, filter_mode: <%= @filter_mode %></p>

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
            <%= band_scope_vertical_grid(@band_scope_mode, freq: @active_frequency, span: @band_scope_span) %>
            <%= band_scope_horizontal_grid() %>

            <polygon id="bandSpectrum" class="spectrum" vector-effect="non-scaling-stroke" points={RadioViewHelpers.scope_data_to_svg(@band_scope_data, max_value: 140, scale_y: @spectrum_scale)}  />
          </g>

          <%= if @split_enabled do %>
            <%= if freq_low(@inactive_frequency, @band_scope_edges) do %>
              <g transform="translate(10 46),rotate(90)">
                <.tx_offscreen_indicator />
              </g>
            <% end %>

            <%= if freq_high(@inactive_frequency, @band_scope_edges) do %>
              <g transform="translate(630 46),rotate(-90)">
                <.tx_offscreen_indicator />
              </g>
            <% end %>
          <% end %>

          <g transform="translate(0 8)">
            <%= if @band_scope_edges do %>
              <text class="bandEdge low" x="5" y="0">
                <%= @band_scope_edges |> format_band_scope_low() %>
              </text>
              <text class="bandEdge high" x="635" y="0">
                <%= @band_scope_edges |> format_band_scope_high() %>
              </text>
            <% end %>

            <%= if @active_frequency do %>
              <text class="bandEdge mid" x="300" y="0"><%= @active_frequency |> format_active_frequency() %></text>
            <% end %>
          </g>

          <g transform="translate(0 20)">
            <%= if @band_scope_edges && @filter_state && @active_mode do %>
              <%= if (@active_mode in [:usb, :lsb, :usb_d, :lsb_d] and @filter_mode in [:hi_lo_cut]) do %>
                <.passband_polygon
                  mode={@active_mode}
                  active_frequency={@active_frequency}
                  filter_mode={@filter_mode}
                  filter_state={@filter_state}
                  scope_edges={@band_scope_edges} />
              <% end %>

              <%= if @split_enabled do %>
                <.carrier_line mode="tx" label="T" frequency={@inactive_frequency} band_scope_edges={@band_scope_edges} piggyback={false}/>
              <% else %>
                <.carrier_line mode="tx" label="T" frequency={@active_frequency} band_scope_edges={@band_scope_edges} piggyback={true} />
              <% end %>

              <.carrier_line mode="rx" label="R" frequency={@active_frequency} band_scope_edges={@band_scope_edges} split_enabled={@split_enabled} />
            <% end %>

            <rect id="bandscopeBackground" x="0" y="0" height="150" width="1280" pointer-events="visibleFill" phx-hook="BandScope" />
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
      <%= for i <- (0..7) do %>
        <line class="bandscopeGrid horizontal" x1="0" y1="<%= i * offset %>" x2="640" y2="<%= i * offset %>" />
      <% end %>
    }
  end

  def passband_polygon(%{
    mode: mode,
    active_frequency: active_frequency,
    filter_state: filter_state,
    filter_mode: filter_mode,
    scope_edges: scope_edges
    } = assigns) when mode in [:usb, :usb_d, :lsb, :lsb_d] do

    points = case filter_mode do
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
        Logger.warn("Unimplemented shift_width passband_polygon for: #{mode}")
        ""

      _ ->
        Logger.warn("Unknown mode/filter mode combination: #{mode}/#{filter_mode}")
        ""
    end

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

    Logger.debug("passband_polygon: cw mode")

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
    Logger.debug("passband_polygon: default case")
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

  def carrier_line(%{frequency: frequency, band_scope_edges: band_scope_edges, mode: mode} = assigns) do
    loc = project_to_bandscope_limits(frequency, band_scope_edges)

    tri_ofs = 10
    tri_text_x = loc - 3

    triangle_points = "#{loc},#{tri_ofs} #{loc - tri_ofs},0 #{loc + tri_ofs},0"

    label_translate = case assigns[:piggyback] do
      true -> "translate(0 -#{tri_ofs})"
      _ -> "translate(0 0)"
    end

    label = case mode do
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
