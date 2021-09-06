defmodule Open890Web.Components.Slider do
  use Phoenix.Component

  def slider(assigns) do
    ~H"""
      <div class="slider">
        <span class="label"><%= @label %></span>
        <div class="sliderWrapper" phx-hook="Slider" data-click-action={@click} data-wheel-action={@wheel} id={id_for(@label)}>
          <div class="indicator" style={style_attr(@value)}></div>
        </div>
      </div>
    """
  end

  def style_attr(value) do
    "width: #{value}px;"
  end

  def id_for(label) do
    "#{label}Slider"
  end
end
