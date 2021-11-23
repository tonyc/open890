defmodule Open890Web.Components.UtilButtons do
  use Phoenix.Component
  use Phoenix.HTML

  def popout_link(assigns) do
    ~H"""
      <%= link @text, to: @to, target: "_blank", phx_hook: "PopoutBandscope", id: @id %>
      <i class="icon external alternate"></i>
    """
  end
end
