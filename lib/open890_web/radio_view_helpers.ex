defmodule Open890Web.RadioViewHelpers do
  require Logger

  import Phoenix.HTML
  import Phoenix.HTML.Tag

  alias Open890.{Menu, TransverterState}

  def selected_theme?(theme, name) do
    if theme == name, do: "selected"
  end

  def cmd_button(name, cmd, opts \\ []) when is_binary(name) and is_binary(cmd) do
    class_opts = opts |> Keyword.get(:class, "")

    # icon_opts = opts |> Keyword.get(:icon)

    final_opts =
      opts
      |> Keyword.delete(:class)
      |> Keyword.merge(class: "ui button #{class_opts}")
      |> Keyword.merge(phx_click: "cmd", phx_value_cmd: cmd)

    content_tag(:button, name, final_opts)
  end

  def cmd_label_button(name, cmd, opts \\ []) when is_binary(name) and is_binary(cmd) do
    class_opts = opts |> Keyword.get(:class, "")

    final_opts =
      opts
      |> Keyword.delete(:class)
      |> Keyword.merge(class: "ui button #{class_opts}")
      |> Keyword.merge(phx_click: "cmd", phx_value_cmd: cmd)

    content_tag(:button, name, final_opts)
  end

  # cycle_button("Scope Mode", @scope_mode, %{auto_scroll: "BS30", fixed: "BS32", center: "BS31"}
  def cycle_button(title, var, values, opts \\ []) when is_map(values) do
    values
    |> Map.get(var)
    |> case do
      nil -> ""
      cmd -> cmd_button(title, cmd, opts)
    end
  end

  def cycle_label_button(title, var, values, opts \\ []) when is_map(values) do
    values
    |> Map.get(var)
    |> case do
      nil ->
        ""

      %{label: label, cmd: cmd} ->
        cmd_label_button(title, label, cmd, opts)
    end
  end

  def cmd_label_button(title, label, cmd, opts) do
    class_opts = opts |> Keyword.get(:class, "")
    button_classes = "ui button #{class_opts}"

    contents =
      case title do
        blank when blank in ["", nil] -> label
        str -> "#{str}: #{label}"
      end

    content_tag(:button, contents, class: button_classes, phx_click: "cmd", phx_value_cmd: cmd)
  end

  def vfo_switch_button(vfo, opts \\ []) do
    "A / B" |> cmd_button(vfo_switch_command(vfo), opts)
  end

  def q_min_button(opts \\ []) do
    "Q-M.IN" |> cmd_button("QI", opts)
  end

  defp vfo_switch_command(:a), do: "FR1"
  defp vfo_switch_command(:b), do: "FR0"

  def vfo_equalize_button(opts \\ []) do
    "A = B" |> cmd_button("VV", opts)
  end

  def vfo_mem_switch_button(vfo_mem_state, opts \\ []) do
    "M / V" |> cmd_button(vfo_mem_switch_command(vfo_mem_state), opts)
  end

  defp vfo_mem_switch_command(:vfo), do: "MV1"
  defp vfo_mem_switch_command(:memory), do: "MV0"

  # converts the kenwood ref level (BSC) command number to a dB value from -20 to +10
  def format_ref_level(ref_level) do
    ref_level / 2.0 - 20
  end

  def format_band_scope_mode(mode) do
    mode
    |> case do
      :auto_scroll -> "Auto Scroll"
      :fixed -> "Fixed"
      :center -> "Center"
    end
  end

  def format_band_scope_att(level) do
    level
    |> case do
      0 -> "OFF"
      1 -> "10 dB"
      2 -> "20 dB"
      3 -> "30 dB"
    end
  end

  def format_rf_pre(level) do
    level
    |> case do
      0 -> "OFF"
      str -> str |> to_string()
    end
  end

  def format_rf_att(level) do
    level
    |> case do
      0 -> "OFF"
      1 -> "6dB"
      2 -> "12dB"
      3 -> "18dB"
    end
  end

  def linear_interpolate(value, y_min, y_max, x_min, x_max) do
    percent = (value - y_min) / (y_max - y_min)
    percent * (x_max - x_min) + x_min
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

  def screen_to_frequency(scope_coord, {low, high}, width) do
    coord_percentage = scope_coord / width

    f_delta = high - low

    (low + coord_percentage * f_delta)
    |> round()
  end

  # formats a raw frequency in Hz to e.g.
  # 7.055.123
  def format_raw_frequency(str) do
    str
    |> to_string()
    |> String.trim_leading("0")
    |> String.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3, 3, [])
    |> Enum.join(".")
    |> String.reverse()
  end

  def s_meter_value_to_s_units(val) when is_integer(val) do
    cond do
      val >= 70 -> "S9+60"
      val >= 58 -> "S9+40"
      val >= 47 -> "S9+20"
      val >= 35 -> "S9"
      val >= 27 -> "S7"
      val >= 19 -> "S5"
      val >= 11 -> "S3"
      val >= 3 -> "S1"
      true -> "S0"
    end
  end

  def number_to_short(value) when is_integer(value) do
    cond do
      value == 15000 -> "15k"
      value == 6000 -> "6k"
      value == 2700 -> "2.7k"
      true -> value |> to_string()
    end
  end

  def number_to_short(_) do
    ""
  end

  def format_mode(mode) when is_atom(mode) or is_binary(mode) do
    mode
    |> to_string()
    |> String.replace("_", "-")
    |> String.upcase()
  end

  def esc_button(opts \\ []) do
    cmd_button("ESC", "DS3", opts)
  end

  def cwt_button(opts \\ []) do
    "CW Tune" |> cmd_button("CA1", opts)
  end

  def scope_data_to_svg(band_data, opts \\ []) when is_list(band_data) do
    max_value = opts[:max_value]
    scale_y = opts[:scale_y] || 1.0

    scaled_max = max_value * scale_y

    band_data =
      band_data
      |> Enum.map(fn v ->
        # THIS WORKS
        # v = linear_interpolate(v, 0, max_value, scaled_max, 0)
        # v = v * scale_y
        # linear_interpolate(v, scaled_max, 0, 0, max_value)

        v
        |> linear_interpolate(0, max_value, scaled_max, 0)
        |> Kernel.*(scale_y)
        |> linear_interpolate(scaled_max, 0, 0, max_value)
      end)

    band_data = band_data ++ [max_value]
    length = band_data |> Enum.count()

    0..length
    |> Enum.zip(band_data)
    |> Enum.map(fn {index, data} ->
      "#{index},#{data}"
    end)
    |> Enum.join(" ")
    |> case do
      str -> "#{str} 0,#{max_value}"
    end
  end

  def format_band_scope_low({low, _high}) do
    low |> format_raw_frequency()
  end

  def format_band_scope_high({_low, high}) do
    high |> format_raw_frequency()
  end

  def center_carrier_line do
    tri_ofs = 10

    ~e{
      <line id="active_receiver_line" class="primaryCarrier" x1="320" y1="0" x2="320" y2="150" />
      <g id="rxTriangleGroup">
        <polygon class="rx triangle" points="320,<%= tri_ofs %> <%= 320 - tri_ofs %>,0 <%= 320 + tri_ofs %>,0" />
        <text class="rx triangleText" x="<%= 320 - 3 %>" y="7">R</text>
      </g>
    }
  end

  def carrier_line(active_frequency, band_scope_edges) do
    loc = project_to_bandscope_limits(active_frequency, band_scope_edges)
    tri_ofs = 10

    ~e{
      <line id="active_receiver_line" class="primaryCarrier" x1="<%= loc %>" y1="0" x2="<%= loc %>" y2="150" />
      <g id="rxTriangleGroup">
        <polygon class="rx triangle" points="<%= loc %>,<%= tri_ofs %> <%= loc - tri_ofs %>,0 <%= loc + tri_ofs %>,0" />
        <text class="rx triangleText" x="<%= loc - 3 %>" y="7">R</text>
      </g>
    }
  end

  def band_scope_horizontal_grid do
    offset = 140 / 8

    ~e{
      <%= for i <- (1..7) do %>
        <line class="bandscopeGrid horizontal" x1="0" y1="<%= i * offset %>" x2="640" y2="<%= i * offset %>" />
      <% end %>
    }
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

  def passband_polygon(mode, active_frequency, filter_lo_width, filter_hi_shift, scope_edges)
      when mode in [:lsb, :usb] do
    filter_low =
      mode
      |> offset_frequency(active_frequency, filter_lo_width)
      |> project_to_bandscope_limits(scope_edges)

    filter_high =
      mode
      |> offset_frequency(active_frequency, filter_hi_shift)
      |> project_to_bandscope_limits(scope_edges)

    ~e{<polygon id="passband" points="<%= filter_low %>,0 <%= filter_high %>,0 <%= filter_high %>,150 <%= filter_low %>,150" />}
  end

  def passband_polygon(mode, active_frequency, filter_lo_width, filter_hi_shift, scope_edges)
      when mode in [:cw, :cw_r] do
    half_width = (filter_lo_width / 2) |> round()

    shift =
      case mode do
        :cw_r -> -filter_hi_shift
        _ -> filter_hi_shift
      end

    filter_low =
      (active_frequency + half_width + shift) |> project_to_bandscope_limits(scope_edges)

    filter_high =
      (active_frequency - half_width + shift) |> project_to_bandscope_limits(scope_edges)

    ~e{<polygon id="passband" points="<%= filter_low %>,0 <%= filter_high %>,0 <%= filter_high %>,150 <%= filter_low %>,150" />}
  end

  def passband_polygon(_mode, _active_frequency, _filter_lo_width, _filter_hi_shift, _scope_edges) do
    ""
  end

  def project_to_audioscope_limits(value, width)
      when is_integer(value) and is_integer(width) do
    percentage = value / width
    percentage * 212
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

    half_shift =
      case mode do
        :cw_r -> filter_hi_shift
        _ -> -filter_hi_shift
      end
      |> div(2)

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

  @doc """
  Offsets +freq+ by +amount+ in the direction of the +mode+'s sideband.
  For USB and CW, this means higher in frequency. For LSB/CW-R, lower in frequency.
  """
  def offset_frequency(mode, freq, amount) when mode in [:usb, :cw] do
    freq + amount
  end

  def offset_frequency(mode, freq, amount) when mode in [:lsb, :cw_r] do
    freq - amount
  end

  def offset_frequency(mode, freq, _amount) do
    Logger.debug("offset_frequency: Unknown mode: #{inspect(mode)}")

    freq
  end

  @doc """
  Offsets +freq+ by +amount+ in the opposite direction of +mode+'s sideband.
  The opposite of offset_frequency/3
  """
  def offset_frequency_reverse(mode, freq, amount) when mode in [:usb, :cw] do
    freq - amount
  end

  def offset_frequency_reverse(mode, freq, amount) when mode in [:lsb, :cw_r] do
    freq + amount
  end

  def debug_assigns(assigns, opts \\ []) do
    assigns
    |> Map.drop([:__changed__, :socket])
    |> Map.drop(opts |> Keyword.get(:except, []))
    |> inspect(pretty: true, limit: :infinity, charlists: :as_lists)
  end

  def render_menu_items(id) do
    Menu.get(id)
    |> case do
      {:ok, menu} ->
        ~e{
          <%= for item <- menu.items do %>
          <a class="item" phx-click="open_menu_by_id", phx-value-id="<%= item.menu_id%>">
            <%= item.title %>
            &mdash;
            <em><%= item.info %></em>
            <div class="ui label"><%= item.num %></div>
          </a>
          <% end %>
        }

      _ ->
        ~e{
          <a class="item">Unknown menu</a>
        }
    end
  end

  def round_up_to_step(value, step) when is_integer(value) and is_integer(step) do
    div(value, step) * step + step
  end

  def vfo_display_frequency(freq, %TransverterState{} = state) do
    state
    |> TransverterState.apply_offset(freq)
    |> format_raw_frequency()
  end

  def str_if(condition, true_str, false_str \\ "") when is_boolean(condition) and is_binary(true_str) and is_binary(false_str) do
    if condition do
      true_str
    else
      false_str
    end
  end

end
