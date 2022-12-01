defmodule Open890Web.Components.Slider do
  use Phoenix.Component

  def slider(assigns) do
    labeled = !is_nil(assigns[:label]) && assigns[:label] != ""

    ~H"""
      <div class={component_classes(assigns)}>
        <%= if labeled do %>
          <span class="label"><%= @label %></span>
        <% end %>
        <div class={wrapper_class(assigns)} phx-hook="Slider" data-click-action={@click} data-wheel-action={@wheel} id={id_for(@label)}
          data-enabled={enabled_state(assigns)}>
          <div class="indicator" style={style_attr(@value)}></div>
        </div>
      </div>
    """
  end

  def enabled_state(assigns) do
    assigns
    |> Map.get(:enabled, true)
    |> to_string()
  end

  def style_attr(value) do
    "width: #{value}px;"
  end

  def id_for(label) do
    "#{label}Slider"
  end

  def component_classes(assigns) do
    top_padded = assigns |> Map.get(:padded_top, false)

    component_classes = ["slider"]

    component_classes =
      if top_padded do
        component_classes ++ ["padded-top"]
      else
        component_classes
      end

    Enum.join(component_classes, " ")
  end

  def wrapper_class(assigns) do
    label = assigns.label
    enabled = assigns |> Map.get(:enabled, true)
    wrapper_classes = ["sliderWrapper"]

    wrapper_classes =
      if !is_nil(label) && label != "" do
        wrapper_classes ++ ["labeled"]
      else
        wrapper_classes
      end

    wrapper_classes =
      if enabled do
        wrapper_classes ++ ["enabled"]
      else
        wrapper_classes ++ ["disabled"]
      end

    Enum.join(wrapper_classes, " ")
  end
end
