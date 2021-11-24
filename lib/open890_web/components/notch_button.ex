defmodule Open890Web.Components.NotchButton do
  use Open890Web, :live_component

  alias Open890.NotchState
  import Open890Web.RadioViewHelpers

  def render(assigns) do
    ~H"""
      <div class="ui small black buttons">

        <%= cycle_button("NCH #{format_notch(@notch_state)}", @notch_state.enabled, %{
          false => "NT1",
          true => "NT0"
        }, class: "small black button") %>

        <%= if @notch_state.enabled do %>
          <%= cycle_button("#{format_notch_width(@notch_state)}", @notch_state.width, %{
            :narrow => "NW1",
            :mid => "NW2",
            :wide => "NW0"
          }, class: "small black button") %>
        <% else %>
            <button class="small black ui disabled button">
              <%= format_notch_width(@notch_state) %>
            </button>
        <% end %>

      </div>
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
end
