defmodule Open890Web.Components.Buttons do
  use Phoenix.Component

  alias Open890.NotchState
  import Open890Web.RadioViewHelpers

  def notch_button(assigns) do
    ~H"""
      <div class="ui small black buttons">
        <%= cycle_button("NCH #{format_notch(@notch_state)}", @notch_state.enabled, %{
          false => "NT1",
          true => "NT0"
        }) %>

        <%= if @notch_state.enabled do %>
          <%= cycle_button("#{format_notch_width(@notch_state)}", @notch_state.width, %{
            :narrow => "NW1",
            :mid => "NW2",
            :wide => "NW0"
          }) %>
        <% else %>
          <button class="ui small disabled button btn">
            <%= format_notch_width(@notch_state) %>
          </button>
        <% end %>
      </div>
    """
  end

  def pre_button(assigns) do
    ~H"""
      <%= cycle_button("PRE #{format_rf_pre(@rf_pre)}", @rf_pre, %{
        0 => "PA1",
        1 => "PA2",
        2 => "PA0"
      }) %>
    """
  end

  def att_button(assigns) do
    ~H"""
      <%= cycle_button("ATT #{format_rf_att(@rf_att)}", @rf_att, %{
        0 => "RA1",
        1 => "RA2",
        2 => "RA3",
        3 => "RA0"
      }) %>
    """
  end

  def nr_button(assigns) do
    ~H"""
      <%= cycle_button("NR #{format_nr(@nr)}", @nr, %{
        :off => "NR1",
        :nr_1 => "NR2",
        :nr_2 => "NR0"
      }) %>
    """
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

  def nb1_button(assigns) do
   ~H"""
    <%= cycle_button("NB1 #{on_off(@noise_blank_state.nb_1_enabled)}", @noise_blank_state.nb_1_enabled, %{
      true => "NB10",
      false => "NB11"
    }) %>
   """
  end

  def nb2_button(assigns) do
   ~H"""
    <%= cycle_button("NB2 #{on_off(@noise_blank_state.nb_2_enabled)}", @noise_blank_state.nb_2_enabled, %{
      true => "NB20",
      false => "NB21"
    }) %>
   """
  end

  def format_notch_width(%NotchState{width: width} = _notch_state) do
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
end
