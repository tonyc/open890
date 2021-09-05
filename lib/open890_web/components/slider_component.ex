defmodule Open890Web.Components.SliderComponent do
  use Phoenix.Component

  def slider(assigns) do
    ~H"""
      <div class="indicator"  style={style_attr(@value)}></div>
    """
  end

  def style_attr(value) do
    "width: #{value}px;"
  end
end
