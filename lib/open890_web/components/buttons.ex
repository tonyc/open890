defmodule Open890Web.Components.Buttons do
  use Phoenix.Component
  require Logger

  alias Open890.NotchState
  import Open890Web.RadioViewHelpers

  def notch_button(assigns) do
    ~H"""
      <div class="ui small black buttons">
        <.cycle_button_2 value={@value.enabled} values={%{false => "NT1", true => "NT0"}}>
          NCH <%= format_notch(@value) %>
        </.cycle_button_2>

        <%= if @value.enabled do %>
          <.cycle_button_2 value={@value.width} values={%{
            :narrow => "NW1",
            :mid => "NW2",
            :wide => "NW0"
          }}>
          </.cycle_button_2>
        <% else %>
            notch not enabled
          <button class="ui small disabled button btn">
            <%= format_notch_width(@value.width) %>
          </button>
        <% end %>
      </div>
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
      <.cycle_button_2 value={@value} values={%{0 => "PA1", 1 => "PA2", 2 => "PA0"}}>
        PRE <%= format_rf_pre(@value) %>
      </.cycle_button_2>
    """
  end

  def att_button(assigns) do
    ~H"""
      <.cycle_button_2 value={@value} values={%{0 => "RA1", 1 => "RA2", 2 => "RA3", 3 => "RA0"}}>
        ATT <%= format_rf_att(@value) %>
      </.cycle_button_2>
    """
  end

  def nr_button(assigns) do
    ~H"""
      <.cycle_button_2 value={@value} values={%{:off => "NR1", :nr_1 => "NR2", :nr_2 => "NR0"}}>
        NR <%= format_nr(@value) %>
      </.cycle_button_2>
    """
  end

  def bc_button(assigns) do
    ~H"""
      <%= if @active_mode not in [:cw, :cw_r] do %>
        <.cycle_button_2 value={@value} values={
          %{
            :off => "BC1",
            :bc_1 => "BC2",
            :bc_2 => "BC0",
          }
        }>BC <%= format_bc(@value) %></.cycle_button_2>
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
    ~H"""
      <.cycle_button_2 value={@value} values={%{:a => "FR1", :b => "FR0"}}>
        A / B
      </.cycle_button_2>
    """
  end

  def vfo_equalize_button(assigns) do
    ~H"""
      <.cmd_button_2 cmd="VV">A = B</.cmd_button_2>
    """
  end

  def vfo_mem_button(assigns) do
    ~H"""
      <.cycle_button_2 value={@value} values={%{:vfo => "MV1", :memory => "MV0"}}>
        M / V
      </.cycle_button_2>
    """
  end

  def nb1_button(assigns) do
    values = %{true => "NB10", false => "NB11"}

    ~H"""
      <.cycle_button_2 value={@value.nb_1_enabled} values={values}}>
        NB1 <%= on_off(@value.nb_1_enabled) %>
      </.cycle_button_2>
    """
  end

  def nb2_button(assigns) do
    ~H"""
      <.cycle_button_2 value={@value.nb_2_enabled} values={ %{true => "NB20", false => "NB21"}}>
        NB2 <%= on_off(@value.nb_2_enabled) %>
      </.cycle_button_2>
    """
  end

  def filter_buttons(assigns) do
    ~H"""
      <.cmd_button_2 cmd="FL00">FIL A</.cmd_button_2>
      <.cmd_button_2 cmd="FL01">FIL B</.cmd_button_2>
      <.cmd_button_2 cmd="FL02">FIL C</.cmd_button_2>
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
    cmd = assigns[:values] |> Map.get(assigns[:value])

    ~H"""
      <.cmd_button_2 cmd={cmd}>
        <%= render_slot(@inner_block) %>
      </.cmd_button_2>
    """
  end

  def cycle_label_button(assigns) do
    %{label: label, cmd: cmd} = assigns[:values] |> Map.get(assigns[:value])

    ~H"""
      <.cmd_button_2 cmd={cmd}>
        <%= render_slot(@inner_block) %> <%= label %>
      </.cmd_button_2>
    """
  end

  def cmd_button_2(assigns) do
    fluid_class = assigns |> Map.get(:fluid, false)
    |> case do
      true -> "fluid"
      _ -> ""
    end

    assigned_classes = assigns[:classes] || ""
    classes = "ui small black button #{assigned_classes} #{fluid_class}"

    ~H"""
      <button class={classes} phx-click="cmd" phx-value-cmd={@cmd}>
        <%= render_slot(@inner_block) %>
      </button>
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
        }></.cycle_label_button>
      <% end %>
    """
  end

  def scope_range_button(assigns) do
    ~H"""
      <%= if @band_scope_mode == :fixed do %>
        <button class="ui black button">Range: (fixme)</button>
      <% else %>
        <div class="ui small compact labeled buttons">
          <.cycle_button_2 value={@band_scope_span} values={
            %{
              5 => "BS47",
              10 => "BS40",
              20 => "BS41",
              30 => "BS42",
              50 => "BS43",
              100 => "BS44",
              200 => "BS45",
              500 => "BS46"
            }}>▼</.cycle_button_2>

          <div class="ui black button">Span: <%= @band_scope_span %> kHz</div>

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
          }>▲</.cycle_button_2>
      <% end %>
    """
  end

  def ref_level_control(assigns) do
    ~H"""
      <div class="ui small compact black button" id="RefLevelControl">
        <form class="" id="refLevel" phx-change="ref_level_changed">
          Ref Level
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
    ~H"""
      <%= if @band_scope_att do %>
        <div class="ui small compact black buttons">
          <.cycle_button_2 value={@band_scope_att} values={
            %{
              0 => "BS83",
              1 => "BS80",
              2 => "BS81",
              3 => "BS82",
            }
          }>▼</.cycle_button_2>

          <div class="ui button">Scope ATT:<%= format_band_scope_att(@band_scope_att) %></div>

          <.cycle_button_2 value={@band_scope_att}, values={%{
              0 => "BS81",
              1 => "BS82",
              2 => "BS83",
              3 => "BS80",
          }}>▲</.cycle_button_2>

        </div>
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
    ~H"""
      <%= if @band_scope_avg do %>
        <div class="ui small compact black buttons">
          <.cycle_button_2 value={@band_scope_avg} values={
            %{
              0 => "BSA3",
              1 => "BSA0",
              2 => "BSA1",
              3 => "BSA2",
            }
          }>▼</.cycle_button_2>

          <div class="ui button">Scope Avg: <%= @band_scope_avg %></div>

          <.cycle_button_2 value={@band_scope_avg} values={
            %{
              0 => "BSA1",
              1 => "BSA2",
              2 => "BSA3",
              3 => "BSA0",
            }
          }>▲</.cycle_button_2>
        </div>
      <% end %>
    """
  end

  def waterfall_speed_control(assigns) do
    ~H"""
      <div class="ui small compact black button">
        <form id="WaterfallSpeed" phx-hook="WaterfallSpeedForm">
          WF Speed: 1 /
          <input class="miniTextInput" name="value" type="number" min="1" max="100" step="1" value={@value} />
        </form>
      </div>
    """
  end

  def spectrum_scale_control(assigns) do
    ~H"""
      <div class="ui small compact black button">
        <form id="SpectrumScale" phx-hook="SpectrumScaleForm">
          Spectrum Scale
          <input class="miniTextInput" name="value" type="number" min="1" max="10" step="0.1" value={@value} />
        </form>
      </div>
    """
  end

  def data_speed_control(assigns) do
    ~H"""
      <%= if @value do %>
        <.cycle_label_button value={@value} values={
          %{
            1 => %{label: "High", cmd: "DD03"},
            2 => %{label: "Mid", cmd: "DD01"},
            3 => %{label: "Low", cmd: "DD02"},
          }}>Data Speed</.cycle_label_button>
      <% end %>
    """
  end

  def pop_out_bandscope_button(assigns) do
    ~H"""
      <%= if !@popout do %>
        <div class="ui small compact black button" phx-hook="PopoutBandscope" data-connection-id={@radio_connection.id} id="bandscope_popout">
          Popout &nbsp;
          <i class="icon external alternate"></i>
        </div>
      <% end %>
    """
  end
end
