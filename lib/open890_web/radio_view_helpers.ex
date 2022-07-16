defmodule Open890Web.RadioViewHelpers do
  require Logger

  import Phoenix.HTML
  import Phoenix.HTML.Tag

  alias Open890.{Menu, RadioState, TransverterState}

  def selected_theme?(theme, name) do
    if theme == name, do: "selected"
  end

  def linear_interpolate(value, y_min, y_max, x_min, x_max) do
    percent = (value - y_min) / (y_max - y_min)
    percent * (x_max - x_min) + x_min
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

  def format_rit_xit(nil), do: "0"

  def format_rit_xit(val) when is_integer(val) do
    is_negative = val < 0

    padding = if is_negative, do: 6, else: 5

    (val / 1000.0)
    |> to_string()
    |> String.pad_trailing(padding, "0")
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

  @doc """
  Offsets +freq+ by +amount+ in the direction of the +mode+'s sideband.
  For USB and CW, this means higher in frequency. For LSB/CW-R, lower in frequency.
  """
  def offset_frequency(mode, freq, amount) when mode in [:usb, :usb_d, :cw] do
    freq + amount
  end

  def offset_frequency(mode, freq, amount) when mode in [:lsb, :lsb_d, :cw_r] do
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
  def offset_frequency_reverse(mode, freq, amount) when mode in [:usb, :cw] and is_integer(amount) do
    freq - amount
  end

  def offset_frequency_reverse(mode, freq, amount) when mode in [:lsb, :cw_r] and is_integer(amount) do
    freq + amount
  end

  def offset_frequency_reverse(_mode, freq, nil) do
    freq
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

  def vfo_display_frequency(freq, %TransverterState{} = state) do
    state
    |> TransverterState.apply_offset(freq)
    |> format_raw_frequency()
  end

  def str_if(condition, true_str, false_str \\ "")
      when is_boolean(condition) and is_binary(true_str) and is_binary(false_str) do
    if condition do
      true_str
    else
      false_str
    end
  end

  def format_agc(agc) when is_atom(agc) do
    case agc do
      :off -> "OFF"
      :slow -> "S"
      :med -> "M"
      :fast -> "F"
      _ -> ""
    end
  end

  def format_agc_topbar(agc_off, agc_state) when is_atom(agc_state) do
    if agc_off do
      " OFF"
    else
      case agc_state do
        :slow -> "-S"
        :med -> "-M"
        :fast -> "-F"
        _ -> ""
      end
    end
  end

  def format_connection_state(state) do
    case state do
      :up -> "Connected"
      :stopped -> "Disconnected"
      :starting -> "Connecting"
      {:down, :econnrefused} -> "Connection Refused"
      {:down, :tcp_closed} -> "TCP Connection Closed"
      {:down, :tcp_noreply} -> "TCP Noreply"
      {:down, :ehostunreach} -> "Host Unreachable"
      {:down, :timeout} -> "Connection Timeout"
      {:down, :kns_in_use} -> "KNS Connection Already In Use"
      {:down, :bad_credentials} -> "Incorrect username or password"
      nil -> "Connection Down"
      other -> inspect(other)
    end
  end

  def connection_startable?(connection_state) do
    case connection_state do
      :stopped -> true
      {:down, _} -> true
      nil -> true
      _ -> false
    end
  end

  def connection_status_icon(connection_state) do
    case connection_state do
      :up ->
        ~e{<i class="linkify icon"></i>}

      :stopped ->
        ~e{<i class="unlink icon"></i>}

      {:down, _} ->
        ~e{}

      _ ->
        ""
    end
  end

  def on_off(flag) do
    if flag, do: "ON", else: "OFF"
  end

  def simple_state(value) do
    value
    |> to_string()
    |> String.last()
    |> case do
      "0" -> "OFF"
      other -> other
    end
  end
end
