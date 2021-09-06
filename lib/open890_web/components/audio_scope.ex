defmodule Open890Web.Components.AudioScope do
  use Phoenix.Component
  import Phoenix.HTML

  alias Open890Web.RadioViewHelpers

  def audio_scope(assigns) do
    ~H"""
      <div id="audioScopeWrapper" class="hover-pointer _debug">
        <svg id="audioScope" class="scope themed" viewbox="0 0 212 60" phx-hook="AudioScope">
          <defs>
            <lineargradient id="kenwoodAudioScope" x1="0" y1="60" x2="0" y2="0" gradientunits="userSpaceOnUse">
              <stop offset="15%" stop-color="#030356" />
              <stop offset="75%" stop-color="white" />
            </lineargradient>
          </defs>

          <g transform="translate(0 10)">
            <polygon id="audioSpectrum" class="spectrum" points={RadioViewHelpers.scope_data_to_svg(@audio_scope_data, max_value: 60)} vector-effect="non-scaling-stroke" />

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
              RFT: <%= @roofing_filter_data[@active_if_filter] |> RadioViewHelpers.number_to_short() %>
            </text>
          </g>

        </svg>

        <canvas phx-hook="AudioScopeCanvas" id="AudioScopeCanvas" data-theme={@theme} class="waterfall" width="213" height="60"></canvas>
      </div>
    """
  end

  def audio_scope_filter_edges(
        mode,
        {filter_lo_width, filter_hi_shift},
        active_roofing_filter,
        roofing_filter_data
      )
      when mode in [:cw, :cw_r] and is_integer(filter_lo_width) and is_integer(filter_hi_shift) and
             not is_nil(active_roofing_filter) do
    half_width = (filter_lo_width / 2) |> round()

    roofing_width = roofing_filter_data |> Map.get(active_roofing_filter)

    half_shift = filter_hi_shift |> div(2)

    distance = ((half_width |> project_to_audioscope_limits(roofing_width)) / 2) |> round()

    half_shift_projected =
      half_shift
      |> project_to_audioscope_limits(roofing_width)
      |> round()

    low_val = 106 - distance + half_shift_projected
    high_val = 106 + distance + half_shift_projected

    points = audio_scope_filter_points(low_val, high_val)

    ~e{
      <polyline id="audioScopeFilter" points="<%= points %>" />
    }
  end

  def audio_scope_filter_edges(
        mode,
        {filter_lo_width, filter_hi_shift} = _filter_edges,
        _active_roofing_filter,
        _roofing_filter_data
      )
      when mode in [:usb, :lsb, :fm] do
    total_width_hz =
      cond do
        filter_hi_shift >= 3400 -> 5000
        true -> 3000
      end

    [projected_low, projected_hi] =
      [filter_lo_width, filter_hi_shift]
      |> Enum.map(fn val ->
        val
        |> project_to_audioscope_limits(total_width_hz)
        |> round()
      end)

    points = audio_scope_filter_points(projected_low, projected_hi)

    ~e{
      <polyline id="audioScopeFilter" points="<%= points %>" />
    }
  end

  def audio_scope_filter_edges(
        :am,
        {filter_lo_width, filter_hi_shift},
        _active_roofing_filter,
        _roofing_filter_data
      ) do
    [projected_low, projected_hi] =
      [filter_lo_width, filter_hi_shift]
      |> Enum.map(fn val ->
        val
        |> project_to_audioscope_limits(5000)
        |> round()
      end)

    points = audio_scope_filter_points(projected_low, projected_hi)

    ~e{
      <polyline id="audioScopeFilter" points="<%= points %>" />
    }
  end

  def audio_scope_filter_edges(_mode, _edges, _active_roofing_filter, _roofing_filter_data) do
    ""
  end

  defp audio_scope_filter_points(low_val, high_val) do
    edge_offset = 7

    "#{low_val - edge_offset},50 #{low_val},5 #{high_val},5 #{high_val + edge_offset},50"
  end

  def project_to_audioscope_limits(value, width)
      when is_integer(value) and is_integer(width) do
    percentage = value / width
    percentage * 212
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
