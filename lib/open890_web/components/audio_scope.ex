defmodule Open890Web.Components.AudioScope do
  require Logger
  use Phoenix.Component
  import Phoenix.HTML

  alias Open890Web.RadioViewHelpers
  alias Open890.{FilterState, NotchState}

  def audio_scope(assigns) do
    ~H"""
      <div class="audioScopeWrapper">
        <svg id="audioScope" class="scope themed" viewbox="0 0 212 60" phx-hook="AudioScope" pointer-events="visible-painted">
          <defs>
            <lineargradient id="kenwoodAudioScope" x1="0" y1="60" x2="0" y2="0" gradientunits="userSpaceOnUse">
              <stop offset="15%" stop-color="#030356" />
              <stop offset="75%" stop-color="white" />
            </lineargradient>
          </defs>

          <g transform="translate(0 10)">
            <polygon id="audioSpectrum" class="spectrum" points={RadioViewHelpers.scope_data_to_svg(@audio_scope_data, max_value: 60)} vector-effect="non-scaling-stroke" />

            <%= if @active_if_filter && @roofing_filter_data[@active_if_filter] do %>
              <%= audio_scope_filter_edges(@active_mode, @filter_state, @filter_mode) %>
            <% end %>

            <line id="audioScopeTuneIndicator" class="carrier rx" x1="106" y1="5" x2="106" y2="60" />

            <%= if @notch_state.enabled do %>
              <.notch_indicator notch_state={@notch_state} active_mode={@active_mode} filter_state={@filter_state} />
            <% end %>
          </g>

          <g transform="translate(3 10)">
            <text class="audioScopeLabel">
              <%= @active_if_filter |> to_string |> String.upcase() %>
            </text>

            <g transform="translate(20 0)">
              <text class="audioScopeLabel">
                <%= filter_lo_width_label(@active_mode, @filter_mode) %>: <%= @filter_state.lo_width %>
              </text>
            </g>

            <g transform="translate(160 0)">
              <text class="audioScopeLabel">
                <%= if @active_mode not in [:fsk, :fsk_r, :psk, :psk_r] do %>
                  <%= filter_hi_shift_label(@active_mode, @filter_mode) %>: <%= @filter_state.hi_shift %>
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

        <canvas phx-hook="AudioScopeCanvas" id="AudioScopeCanvas" data-theme={@theme} class="waterfall hover-pointer" width="213" height="60"></canvas>
      </div>
    """
  end

  def notch_indicator(assigns) do
    ~H"""
      <g id="notchIndicatorGroup" transform={notch_transform(@active_mode, @filter_state, @notch_state)}>
        <line id="notchLocationIndicator" class="" x1="0" y1="5" x2="0" y2="45" />
      </g>
    """
  end

  def notch_transform(_mode, _filter_state, %NotchState{frequency: nil}) do
    "translate(0 0)"
  end

  def notch_transform(mode, filter_state, %NotchState{frequency: frequency}) when mode in [:cw, :cw_r] do
    x_position = cond do
      FilterState.width(filter_state) < 700 ->
        cw_notch_transform_with_width(:narrow, frequency)
      true ->
        cw_notch_transform_with_width(:wide, frequency)
    end

    "translate(#{x_position} 0)"
  end

  def notch_transform(mode, _filter_state, %NotchState{frequency: _frequency}) when mode in [:usb, :lsb, :usb_d, :lsb_d] do
    "translate(0, 0)"
  end

  def cw_notch_transform_with_width(:narrow, frequency) do
    frequency / 255 * 212
  end

  def cw_notch_transform_with_width(:wide, frequency) do
    (frequency / 255)
    |> Kernel.*(212) # scale to total percentage of scope width
    |> Kernel./(3)   # middle 1/3 of the screen - there are six segments in wide mode
    |> Kernel.+(70)  # a magic number I don't know where it comes from, but seems to look right
  end

  def data_filter_points(%FilterState{} = filter_state) do
    filter_width = FilterState.width(filter_state)
    half_width = round(filter_width / 2)

    scope_width = if filter_width <= 500 do
      500
    else
      3000
    end

    center_f = div(scope_width, 2)

    low = center_f - half_width
    high = center_f + half_width

    [low_val, high_val] = [low, high]
                          |> Enum.map(fn x ->
                            x |> project_to_audioscope_limits(scope_width)
                          end)

    audio_scope_filter_points(low_val, high_val)

  end

  def cw_filter_points(%FilterState{} = filter_state) do
    filter_width = FilterState.width(filter_state)
    half_width = round(filter_width / 2)

    scope_width = cond do
      filter_width < 700 -> 500
      true -> 1500
    end

    half_shift = filter_state.hi_shift |> div(2)

    distance = ((half_width |> project_to_audioscope_limits(scope_width)) / 2) |> round()

    half_shift_projected =
      half_shift
      |> project_to_audioscope_limits(scope_width)
      |> round()

    low_val = 106 - distance + half_shift_projected
    high_val = 106 + distance + half_shift_projected

    audio_scope_filter_points(low_val, high_val)
  end

  def shifted_ssb_filter_points(%FilterState{hi_shift: shift} = filter_state) do
    filter_width = FilterState.width(filter_state)
    half_width = div(filter_width, 2)

    # if shift + (width /2) >= 3000, the display changes to a 5k width
    scope_width = if shift + half_width > 3000 do
      5000
    else
      3000
    end

    center_f = div(scope_width, 2)

    shift_delta = center_f - shift

    low = center_f - half_width - shift_delta
    high = center_f + half_width - shift_delta

    [low_val, high_val] = [low, high]
                          |> Enum.map(fn x ->
                            x |> project_to_audioscope_limits(scope_width)
                          end)

    audio_scope_filter_points(low_val, high_val)
  end

  def hi_lo_cut_filter_points(%FilterState{} = filter_state) do
    total_width_hz =
      cond do
        filter_state.hi_shift >= 3400 -> 5000
        true -> 3000
      end

    [projected_low, projected_hi] =
      [filter_state.lo_width, filter_state.hi_shift]
      |> Enum.map(fn val ->
        val
        |> project_to_audioscope_limits(total_width_hz)
        |> round()
      end)

    audio_scope_filter_points(projected_low, projected_hi)
  end

  def audio_scope_filter_edges(mode, %FilterState{} = filter_state, ssb_filter_mode) do
    points = case mode do
      :am -> am_filter_points(filter_state)
      :fm -> hi_lo_cut_filter_points(filter_state)
      x when x in [:cw, :cw_r] -> cw_filter_points(filter_state)
      x when x in [:fsk, :fsk_r, :psk, :psk_r] -> data_filter_points(filter_state)
      x when x in [:usb, :usb_d, :lsb, :lsb_d] ->
        if ssb_filter_mode == :hi_lo_cut do
          hi_lo_cut_filter_points(filter_state)
        else
          shifted_ssb_filter_points(filter_state)
        end

      other ->
        Logger.debug("Unimplemented case for audio_scope_filter_edges for mode #{inspect(other)}")
        ""
    end

    ~e{
      <polyline id="audioScopeFilter" points="<%= points %>" />
    }
  end

  def am_filter_points(%FilterState{lo_width: lo_width, hi_shift: hi_shift}) do
    [projected_low, projected_hi] =
      [lo_width, hi_shift]
      |> Enum.map(fn val ->
        val
        |> project_to_audioscope_limits(5000)
        |> round()
      end)

    audio_scope_filter_points(projected_low, projected_hi)
  end

  defp audio_scope_filter_points(low_val, high_val) do
    edge_offset = 7

    "#{low_val - edge_offset},50 #{low_val},5 #{high_val},5 #{high_val + edge_offset},50"
  end

  def project_to_audioscope_limits(nil, _width), do: 0

  def project_to_audioscope_limits(value, width)
      when is_integer(value) and is_integer(width) do
    percentage = value / width
    percentage * 212
  end

  def filter_lo_width_label(mode, ssb_filter_mode) do
    case mode do
      x when x in [:cw, :cw_r, :fsk, :fsk_r, :psk, :psk_r] -> "WIDTH"
      x when x in [:am, :fm] -> "LC"
      x when x in [:usb, :usb_d, :lsb, :lsb_d] ->
        if ssb_filter_mode == :hi_lo_cut do
          "LC"
        else
          "WIDTH"
        end
      _ -> ""
    end
  end

  def filter_hi_shift_label(mode, ssb_filter_mode) do
    case mode do
      x when x in [:cw, :cw_r] -> "SHIFT"
      x when x in [:am, :fm] -> "HC"
      x when x in [:usb, :usb_d, :lsb, :lsb_d] ->
        if ssb_filter_mode == :hi_lo_cut do
          "HC"
        else
          "SHIFT"
        end
      _ -> ""
    end
  end

end
