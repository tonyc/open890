defmodule Open890Web.Components.Buttons do
  use Phoenix.Component
  require Logger

  import Open890Web.RadioViewHelpers
  alias Open890.{AntennaState, TransverterState, TunerState}

  def proc_button(assigns) do
    ~H"""
      <span class="indicator">
        <%= if @enabled do %>
          <.cmd_button cmd="PR00" classes="mini proc_button enabled">PROC ON</.cmd_button>
        <% else %>
          <.cmd_button cmd="PR01" classes="mini inverted secondary proc_button">PROC OFF</.cmd_button>
        <% end %>
      </span>
    """
  end

  def ant_1_2_button(assigns) do
    %AntennaState{} = ant_state = assigns.value

    label =
      case ant_state.active_ant do
        :ant1 -> "ANT 1"
        _ -> "ANT 2"
      end

    cmd =
      ant_state
      |> AntennaState.toggle_ant()
      |> AntennaState.to_command()

    assigns = assign(assigns, %{
      cmd: cmd,
      label: label
    })

    ~H"""
      <.cmd_button cmd={@cmd} fluid={assigns[:fluid]}><%= @label %></.cmd_button>
    """
  end

  def band_buttons(assigns) do
    ~H"""
      <div class="ui grid">
        <div class="row">
          <div class="four wide column left aligned">

            <div id="modeKeys" class="ui vertical big buttons">
              <.cmd_button tabindex="0" classes="regular" cmd="MK0">LSB/USB</.cmd_button>
              <.cmd_button tabindex="0" classes="regular" cmd="MK1">CW/CW-R</.cmd_button>
              <.cmd_button tabindex="0" classes="regular" cmd="MK2">FSK/PSK</.cmd_button>
              <.cmd_button tabindex="0" classes="regular" cmd="MK3">FM/AM</.cmd_button>
              <.cmd_button tabindex="0" classes="regular" cmd="MK4">FSK/FSK-R</.cmd_button>
              <.cmd_button tabindex="0" classes="regular" cmd="MK5">PSK/PSK-R</.cmd_button>
            </div>

          </div>
          <div class="twelve wide column">
            <div class="ui equal width grid">
              <div class="row">
                <div class="column"><.cmd_button cmd="BU000" classes="big regular" tabindex="0" fluid>1.8</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU001" classes="big regular" tabindex="0" fluid>3.5</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU002" classes="big regular" tabindex="0" fluid>7</.cmd_button></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button cmd="BU003" classes="big regular" tabindex="0" fluid>10</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU004" classes="big regular" tabindex="0" fluid>14</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU005" classes="big regular" tabindex="0" fluid>18</.cmd_button></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button cmd="BU006" classes="big regular" tabindex="0" fluid>21</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU007" classes="big regular" tabindex="0" fluid>24</.cmd_button></div>
                <div class="column"><.cmd_button cmd="BU008" classes="big regular" tabindex="0" fluid>28</.cmd_button></div>
              </div>
              <div class="row">
                <div class="column"><.cmd_button cmd="BU010" classes="big regular" tabindex="0" fluid>GEN</.cmd_button></div>
                <div class="column"></div>
                <div class="column"><.cmd_button cmd="BU009" classes="big regular" tabindex="0" fluid>50</.cmd_button></div>
              </div>
            </div>

          </div>
        </div>
      </div>
    """
  end

  def send_button(assigns) do
    tx_state = assigns.value

    cmd =
      case tx_state do
        :off -> "TX0"
        _ -> "RX"
      end

    assigns = assign(assigns, %{
      cmd: cmd
    })

    ~H"""
      <.cmd_button cmd={@cmd} fluid={assigns[:fluid]}>SEND</.cmd_button>
    """
  end

  def tx_tune_button(assigns) do
    cmd =
      case assigns.value do
        :off -> "TX2"
        _ -> "RX"
      end

    assigns = assign(assigns, :cmd, cmd)

    ~H"""
      <.cmd_button cmd={@cmd} fluid={assigns[:fluid]}>TX TUNE</.cmd_button>
    """
  end

  def rx_button(assigns) do
    ~H"""
      <.cmd_button cmd="RX" fluid={assigns[:fluid]}>RX</.cmd_button>
    """
  end

  def atu_tune_button(assigns) do
    %TunerState{} = tuner_state = assigns.value

    cmd =
      tuner_state
      |> TunerState.toggle_tuning()
      |> TunerState.to_command()

    assigns = assign(assigns, %{
      cmd: cmd
    })

    ~H"""
      <.cmd_button cmd={@cmd} fluid={assigns[:fluid]}>TUNE</.cmd_button>
    """
  end

  def atu_button(assigns) do
    %TunerState{} = tuner_state = assigns.value

    enabled =
      if tuner_state.tx_enabled do
        "ON"
      else
        "OFF"
      end

    cmd =
      tuner_state
      |> TunerState.toggle_tuner_state()
      |> TunerState.to_command()

    assigns = assign(assigns, %{
      cmd: cmd,
      enabled: enabled
    })

    ~H"""
      <.cmd_button cmd={@cmd} fluid={assigns[:fluid]}>ATU <%= @enabled %></.cmd_button>
    """
  end

  def rx_ant_button(assigns) do
    %AntennaState{} = ant_state = assigns.value

    enabled =
      if ant_state.rx_ant_enabled do
        "ON"
      else
        "OFF"
      end

    cmd =
      ant_state
      |> AntennaState.toggle_rx_ant()
      |> AntennaState.to_command()

    assigns = assign(assigns, %{
      cmd: cmd,
      enabled: enabled
    })

    ~H"""
      <.cmd_button cmd={@cmd} fluid={assigns[:fluid]}>RX ANT <%= @enabled %></.cmd_button>
    """
  end

  def ant_out_button(assigns) do
    %AntennaState{} = ant_state = assigns.value

    enabled =
      if ant_state.ant_out_enabled do
        "ON"
      else
        "OFF"
      end

    cmd =
      ant_state
      |> AntennaState.toggle_ant_out()
      |> AntennaState.to_command()

    assigns = assign(assigns, %{
      cmd: cmd,
      enabled: enabled
    })

    ~H"""
      <.cmd_button cmd={@cmd} fluid={assigns[:fluid]}>ANT OUT <%= @enabled %></.cmd_button>
    """
  end

  def drv_button(assigns) do
    %AntennaState{} = ant_state = assigns.value

    enabled =
      if ant_state.drv_enabled do
        "ON"
      else
        "OFF"
      end

    cmd =
      ant_state
      |> AntennaState.toggle_drv()
      |> AntennaState.to_command()

    assigns = assign(assigns, %{
      cmd: cmd,
      enabled: enabled
    })

    ~H"""
      <.cmd_button cmd={@cmd} fluid={assigns[:fluid]}>DRV <%= @enabled %></.cmd_button>
    """
  end

  def xvtr_button(assigns) do
    %TransverterState{} = xvtr_state = assigns.value

    [cmd, enabled] =
      if xvtr_state.enabled do
        ["XV0", "ON"]
      else
        ["XV1", "OFF"]
      end

    assigns = assign(assigns, %{
      cmd: cmd,
      enabled: enabled
    })

    ~H"""
      <.cmd_button cmd={@cmd} fluid={assigns[:fluid]}>XVTR <%= @enabled %></.cmd_button>
    """
  end

  def agc_button(assigns) do
    values = %{slow: "GC3", med: "GC1", fast: "GC2"}

    assigns = assign(assigns, :values, values)

    ~H"""
    <%= if @agc_off do %>
      <div class="ui small black fluid button disabled">
        AGC <%= format_agc(@value) %>
      </div>
    <% else %>
      <.cycle_button_2 value={@value} values={@values} fluid={@fluid}>
        AGC <%= format_agc(@value) %>
      </.cycle_button_2>
    <% end %>
    """
  end

  def agc_off_button(assigns) do
    ~H"""
      <%= if @agc_off do %>
        <.cmd_button cmd={cmd_for_agc(@agc)} fluid={assigns[:fluid]}>AGC OFF</.cmd_button>
      <% else %>
        <.cmd_button cmd="GC0" fluid={assigns[:fluid]}>AGC ON</.cmd_button>
      <% end %>
    """
  end

  def cmd_for_agc(agc_state) when is_atom(agc_state) do
    case agc_state do
      :slow -> "GC1"
      :med -> "GC2"
      :fast -> "GC3"
    end
  end

  def notch_button(assigns) do
    ~H"""
      <%= if @value do %>
        <.cycle_button_2 value={@value.enabled} values={%{false => "NT1", true => "NT0"}} fluid={assigns[:fluid]}>
          NCH <%= format_notch(@value) %>
        </.cycle_button_2>
      <% end %>
    """
  end

  def notch_width_button(assigns) do
    values = %{
      :narrow => "NW1",
      :mid => "NW2",
      :wide => "NW0"
    }

    assigns = assign(assigns, :values, values)

    ~H"""
      <%= if @value.enabled do %>
        <.cycle_button_2 value={@value.width} values={@values} fluid={assigns[:fluid]}>
          NCH <%= format_notch_width(@value.width) %>
        </.cycle_button_2>
      <% else %>
      <div class="ui small disabled black button fluid">
        NCH <%= format_notch_width(@value.width) %>
      </div>
    <% end %>
    """
  end

  def format_notch_width(width) do
    case width do
      :narrow -> "N"
      :mid -> "M"
      :wide -> "W"
      _ -> ""
    end
  end

  def format_notch(notch_state) do
    notch_state.enabled
    |> case do
      true -> "ON"
      false -> "OFF"
      _ -> ""
    end
  end

  def pre_button(assigns) do
    ~H"""
      <.cycle_button_2 value={@value} values={%{0 => "PA1", 1 => "PA2", 2 => "PA0"}} fluid={assigns[:fluid]}>
        PRE <%= format_rf_pre(@value) %>
      </.cycle_button_2>
    """
  end

  def att_button(assigns) do
    ~H"""
      <.cycle_button_2 value={@value} values={%{0 => "RA1", 1 => "RA2", 2 => "RA3", 3 => "RA0"}} fluid={assigns[:fluid]}>
        ATT <%= format_rf_att(@value) %>
      </.cycle_button_2>
    """
  end

  def nr_button(assigns) do
    ~H"""
      <.cycle_button_2 value={@value} values={%{:off => "NR1", :nr_1 => "NR2", :nr_2 => "NR0"}} fluid={assigns[:fluid]}>
        NR <%= format_nr(@value) %>
      </.cycle_button_2>
    """
  end

  def bc_button(assigns) do
    values = %{
      :off => "BC1",
      :bc_1 => "BC2",
      :bc_2 => "BC0"
    }

    assigns = assign(assigns, :values, values)

    ~H"""
      <%= if @active_mode not in [:cw, :cw_r] do %>
        <.cycle_button_2 value={@value} values={@values} fluid={assigns[:fluid]}>
          BC <%= format_bc(@value) %>
        </.cycle_button_2>
      <% else %>
        <div class="ui small black fluid button disabled">BC</div>
      <% end %>
    """
  end

  defp format_bc(bc) do
    case bc do
      :off -> "OFF"
      :bc_1 -> "1"
      :bc_2 -> "2"
      _ -> ""
    end
  end

  def format_nr(nr_state) do
    nr_state
    |> case do
      :off -> "OFF"
      :nr_1 -> "1"
      :nr_2 -> "2"
      _ -> ""
    end
  end

  def vfo_switch_button(assigns) do
    values = %{:a => "FR1", :b => "FR0"}
    assigns = assign(assigns, :values, values)

    ~H"""
      <.cycle_button_2 fluid={assigns[:fluid]} value={@value} values={@values}>
        A / B
      </.cycle_button_2>
    """
  end

  def vfo_equalize_button(assigns) do
    ~H"""
      <.cmd_button cmd="VV" fluid={assigns[:fluid]}>A = B</.cmd_button>
    """
  end

  def memory_transfer_button(assigns) do
    ~H"""
      <.cmd_button cmd="SV" classes="ui small black button fluid">M &gt; V</.cmd_button>
    """
  end

  def vfo_mem_button(assigns) do
    values = %{:vfo => "MV1", :memory => "MV0"}
    assigns = assign(assigns, :values, values)

    ~H"""
      <%= if @value do %>
        <.cycle_button_2 value={@value} values={@values} fluid={assigns[:fluid]}>M/V</.cycle_button_2>
      <% end %>
    """
  end

  def nb1_button(assigns) do
    values = %{true => "NB10", false => "NB11"}
    assigns = assign(assigns, :values, values)

    ~H"""
      <.cycle_button_2 value={@value.nb_1_enabled} values={@values} fluid={assigns[:fluid]}>
        NB1 <%= on_off(@value.nb_1_enabled) %>
      </.cycle_button_2>
    """
  end

  def apf_button(assigns) do
    values = %{true => "AP00", false => "AP01"}
    assigns = assign(assigns, :values, values)

    ~H"""
      <.cycle_button_2 value={@value} values={@values} fluid={assigns[:fluid]}>
        APF <%= on_off(@value) %>
      </.cycle_button_2>
    """
  end

  def nb2_button(assigns) do
    values = %{true => "NB20", false => "NB21"}
    assigns = assign(assigns, :values, values)

    ~H"""
      <.cycle_button_2 value={@value.nb_2_enabled} values={@values} fluid={assigns[:fluid]}>
        NB2 <%= on_off(@value.nb_2_enabled) %>
      </.cycle_button_2>
    """
  end

  def ssb_shift_width_button(assigns) do
    [label, cmd] =
      case assigns.active_mode do
        ssb when ssb in [:usb, :lsb] ->
          case assigns.ssb_filter_mode do
            :shift_width ->
              ["SHIFT/WIDTH", "EX00611 000"]

            _ ->
              ["HI/LO CUT", "EX00611 001"]
          end

        _other ->
          case assigns.ssb_data_filter_mode do
            :shift_width ->
              ["SHIFT/WIDTH", "EX00612 000"]

            _ ->
              ["HI/LO CUT", "EX00612 001"]
          end
      end

    assigns = assign(assigns, %{
      cmd: cmd,
      label: label
    })

    ~H"""
      <.cmd_button cmd={@cmd} classes="ui mini black"><%= @label %></.cmd_button>
    """
  end

  def filter_buttons(assigns) do
    ~H"""
      <div class="ui mini black buttons if-filter-button">
        <.cmd_button cmd="FL00" classes={["if-filter-button", (if @active_if_filter == :a, do: "enabled", else: "")]}>FIL A</.cmd_button>
        <.cmd_button cmd="FL01" classes={["if-filter-button", (if @active_if_filter == :b, do: "enabled", else: "")]}>FIL B</.cmd_button>
        <.cmd_button cmd="FL02" classes={["if-filter-button", (if @active_if_filter == :c, do: "enabled", else: "")]}>FIL C</.cmd_button>
      </div>
    """
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

  def cycle_button_2(assigns) do
    cmd = (assigns[:values] || %{}) |> Map.get(assigns[:value])

    attrs = assigns_to_attributes(assigns, [:values, :value])

    assigns = assign(assigns, %{
      cmd: cmd,
      attrs: attrs
    })

    ~H"""
      <.cmd_button cmd={@cmd} {@attrs}>
        <%= render_slot(@inner_block) %>
      </.cmd_button>
    """
  end

  def cycle_label_button(assigns) do
    %{label: label, cmd: cmd} = assigns[:values] |> Map.get(assigns[:value])

    assigns = assign(assigns, %{
      cmd: cmd,
      label: label
    })

    ~H"""
      <.cmd_button cmd={@cmd} fluid={assigns[:fluid]}>
        <%= render_slot(@inner_block) %> <%= @label %>
      </.cmd_button>
    """
  end

  # attr :tabindex, :number, required: false, default: 0
  def cmd_button(assigns) do
    fluid_class =
      assigns
      |> Map.get(:fluid, false)
      |> case do
        true -> "fluid"
        _ -> ""
      end

    assigned_classes = case assigns[:classes] do
      arr when is_list(arr) -> arr |> Enum.join(" ")
      str when is_binary(str) -> str
      _ -> ""
    end

    size_class =
      if ~w(mini tiny small medium large big huge massive)
         |> Enum.any?(fn size -> assigned_classes |> String.contains?(size) end) do
        ""
      else
        "small"
      end

    color_class =
      if ~w(primary secondary regular)
        |> Enum.any?(fn size -> assigned_classes |> String.contains?(size) end) do
          ""
        else
          "black"
        end

    classes = "ui #{size_class} #{color_class} button #{assigned_classes} #{fluid_class}"

    assigns = assign(assigns, :classes, classes)

    ~H"""
      <div class={@classes} phx-click="cmd" phx-value-cmd={@cmd}>
        <%= render_slot(@inner_block) %>
      </div>
    """
  end

  # band scope buttons
  def scope_mode_button(assigns) do
    ~H"""
      <%= if @band_scope_mode do %>
        <.cycle_label_button value={@band_scope_mode} values={
          %{
            auto_scroll: %{label: "Auto Scroll", cmd: "BS30"},
            fixed: %{label: "Fixed", cmd: "BS32"},
            center: %{label: "Center", cmd: "BS31"}
          }
        } fluid={assigns[:fluid]}></.cycle_label_button>
      <% end %>
    """
  end

  def scope_range_button(assigns) do
    ~H"""
      <%= if @band_scope_mode == :fixed do %>
        <.cycle_button_2 value={@band_scope_fixed_range_number} values={
          %{
            1 => "BS52",
            2 => "BS53",
            3 => "BS51",
          }
        } fluid>
          Range: <%= @band_scope_fixed_range_number %>
        </.cycle_button_2>
      <% else %>
          <.cycle_button_2 value={@band_scope_span} values={
            %{
              5 => "BS41",
              10 => "BS42",
              20 => "BS43",
              30 => "BS44",
              50 => "BS45",
              100 => "BS46",
              200 => "BS47",
              500 => "BS40",
            }
        } fluid>
        Span: <%= @band_scope_span %> kHz
        </.cycle_button_2>
      <% end %>
    """
  end

  def ref_level_control(assigns) do
    ~H"""
      <div class="ui small black fluid button" id="RefLevelControl">
        <form class="" id="refLevel" phx-change="ref_level_changed">
          Ref:
          <input class="miniTextInput" name="refLevel" type="number" min="-20" max="10" step="0.5" value={format_ref_level(@value)} />
          dB
        </form>
      </div>
    """
  end

  # converts the kenwood ref level (BSC) command number to a dB value from -20 to +10
  defp format_ref_level(ref_level) do
    ref_level / 2.0 - 20
  end

  def band_scope_att_button(assigns) do
    values = %{
      0 => "BS81",
      1 => "BS82",
      2 => "BS83",
      3 => "BS80"
    }

    assigns = assign(assigns, :values, values)

    ~H"""
      <%= if @band_scope_att do %>
        <.cycle_button_2 value={@band_scope_att} values={@values} fluid>
          ATT: <%= format_band_scope_att(@band_scope_att) %>
        </.cycle_button_2>
      <% end %>
    """
  end

  defp format_band_scope_att(level) do
    level
    |> case do
      0 -> "OFF"
      1 -> "10 dB"
      2 -> "20 dB"
      3 -> "30 dB"
    end
  end

  def band_scope_avg_button(assigns) do
    values = %{
      0 => "BSA1",
      1 => "BSA2",
      2 => "BSA3",
      3 => "BSA0"
    }
    assigns = assign(assigns, :values, values)

    ~H"""
      <%= if @band_scope_avg do %>
        <.cycle_button_2 value={@band_scope_avg} values={@values} fluid>
          Averaging: <%= @band_scope_avg %>
        </.cycle_button_2>
      <% end %>
    """
  end

  def band_scope_expand_button(assigns) do
    values = %{
      true => "BSO0",
      false => "BSO1"
    }

    label =
      if assigns.band_scope_expand do
        "ON"
      else
        "OFF"
      end

    assigns = assign(assigns, %{
      values: values,
      label: label
    })

    ~H"""
      <.cycle_button_2 value={@band_scope_expand} values={@values} fluid>
        Expand: <%= @label %>
      </.cycle_button_2>
    """
  end

  def waterfall_speed_control(assigns) do
    ~H"""
      <div class="ui small black fluid button">
        <form id="WaterfallSpeed" phx-hook="WaterfallSpeedForm">
          WF speed: 1 /
          <input class="miniTextInput" name="value" type="number" min="1" max="100" step="1" value={@value} />
        </form>
      </div>
    """
  end

  def spectrum_scale_control(assigns) do
    ~H"""
      <div class="ui small black fluid button">
        <form id="SpectrumScale" phx-hook="SpectrumScaleForm">
          Scale:
          <input class="miniTextInput" name="value" type="number" min="1" max="10" step="0.1" value={@value} />
        </form>
      </div>
    """
  end

  def data_speed_control(assigns) do
    ~H"""
      <%= if @value do %>
        <.cycle_label_button fluid={assigns[:fluid]} value={@value} values={
          %{
            1 => %{label: "High", cmd: "DD03"},
            2 => %{label: "Mid", cmd: "DD01"},
            3 => %{label: "Low", cmd: "DD02"},
          }}>Data Speed: </.cycle_label_button>
      <% end %>
    """
  end

  def pop_out_bandscope_button(assigns) do
    ~H"""
      <%= if !assigns[:popout] do %>
        <div class="ui small black fluid button" phx-hook="PopoutBandscope" data-connection-id={@radio_connection.id} id="bandscope_popout">
          Popout &nbsp;
          <i class="icon external alternate"></i>
        </div>
      <% end %>
    """
  end
end
